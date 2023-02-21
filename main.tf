data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_vpc" "specified" {
  id = var.vpc_id
}

locals {
  state_parameter_arn = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.name}/tailscale-vpn-state"
}

resource "aws_ecs_cluster" "default" {
  name = var.name
}

resource "aws_cloudwatch_log_group" "default" {
  name              = "ecs/${var.name}"
  retention_in_days = 30
}

data "aws_iam_policy_document" "allow_ecs_tasks_service" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "execution" {
  name               = "${var.name}-execution"
  assume_role_policy = data.aws_iam_policy_document.allow_ecs_tasks_service.json
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task" {
  name               = "${var.name}-task"
  assume_role_policy = data.aws_iam_policy_document.allow_ecs_tasks_service.json
}

resource "aws_iam_role_policy" "task" {
  role = aws_iam_role.task.id

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"

          Action = [
            "ssm:GetParameter",
            "ssm:PutParameter"
          ]

          Resource = [local.state_parameter_arn]
        }
      ]
    }
  )
}

locals {
  vpc_routes = [for a in data.aws_vpc.specified.cidr_block_associations : a.cidr_block]
}

resource "aws_ecs_task_definition" "default" {
  family = var.name

  container_definitions = jsonencode(
    [
      {
        name  = var.name
        image = "tailscale/tailscale:v1.36.1"

        linuxParameters = {
          initProcessEnabled = true
        }

        logConfiguration = {
          logDriver = "awslogs"
          options = {
            "awslogs-group"         = aws_cloudwatch_log_group.default.name
            "awslogs-region"        = data.aws_region.current.name
            "awslogs-stream-prefix" = var.name
          }
        }

        environment = [
          {
            name  = "TS_AUTH_KEY"
            value = var.tailscale_auth_key
          },
          {
            name  = "TS_ROUTES"
            value = join(",", concat(local.vpc_routes, var.additional_routes))
          },
          {
            name  = "TS_USERSPACE"
            value = "1"
          },
          {
            name  = "TS_EXTRA_ARGS"
            value = "--hostname ${var.name}"
          },
          {
            name  = "TS_TAILSCALED_EXTRA_ARGS",
            value = "--state ${local.state_parameter_arn}"
          }
        ]
      }
    ]
  )

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn
}

resource "aws_ecs_service" "default" {
  name                   = var.name
  cluster                = aws_ecs_cluster.default.name
  task_definition        = aws_ecs_task_definition.default.arn
  launch_type            = "FARGATE"
  desired_count          = 1
  enable_execute_command = true

  network_configuration {
    assign_public_ip = true
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
  }
}
