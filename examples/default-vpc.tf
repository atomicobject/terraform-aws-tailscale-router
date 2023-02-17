# Deploys a Tailscale subnet router into the default VPC.

data "aws_vpc" "default" {
  default = true
}

data "aws_security_group" "default_vpc_default" {
  vpc_id = data.aws_vpc.default.id
  name   = "default"
}

data "aws_subnets" "default_vpc" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Set TF_VAR_tailscale_auth_key in your environment, or pass on the command line
variable "tailscale_auth_key" {
  type      = string
  sensitive = true
}

module "router" {
  source  = "atomicobject/tailscale-router/aws"
  version = ">= 1.0.0, < 2.0.0"

  name               = "tailscale-subnet-router"
  tailscale_auth_key = var.tailscale_auth_key
  vpc_id             = data.aws_vpc.default.id
  subnet_ids         = data.aws_subnets.default_vpc.ids
  security_group_ids = [data.aws_security_group.default_vpc_default.id]
}
