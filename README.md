# terraform-aws-tailscale-router

Puts a [Tailscale](https://tailscale.com/) [subnet router](https://tailscale.com/kb/1019/subnets/), running on AWS in an [ECS](https://aws.amazon.com/ecs/) container, into your [VPC](https://aws.amazon.com/vpc/) with minimal configuration.

You can read more about this module in ["Get VPN access into your AWS VPC with Tailscale"](https://spin.atomicobject.com/2023/03/16/aws-vpc-tailscale/) at [Atomic Spin](https://spin.atomicobject.com/).

## Quick start

If you just want to deploy into the default VPC and default security group, data sources can get you everything you need save the [auth key](#getting-an-auth-key):

```
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
```

Pick a name (this will be used for many things, including the ECS cluster that will be launched to contain your router), and you can add the router to your Terraform configuration:

```
module "router" {
  source  = "atomicobject/tailscale-router/aws"
  version = ">= 1.1.4, < 2.0.0"

  name               = "tailscale-subnet-router"
  tailscale_auth_key = var.tailscale_auth_key
  vpc_id             = data.aws_vpc.default.id
  subnet_ids         = data.aws_subnets.default_vpc.ids
  security_group_ids = [data.aws_security_group.default_vpc_default.id]
}
```

[Other configurations](#other-configurations) are also possible.

## Getting an auth key

An auth key is required to authenticate your router to your tailnet.  Go to [keys](https://login.tailscale.com/admin/settings/keys) in Tailscale admin, and generate a new auth key here.

Once your router is authenticated, the auth key is no longer needed, as the node key will be used.

For more information, see [the documentation](https://tailscale.com/kb/1085/auth-keys/).

## Other configurations

Deploying into other VPCs is also relatively straightforward; you just need the VPC id and the subnet ids you want to launch into.

Depending on your setup, you may also need to launch your router into different security groups. The default security group AWS created allows traffic only from itself, so using it for the router will allow access to anything else in that security group.

If you want to use different security groups, you'll have to make sure there are appropriate ingress rules to support the router.

**NEW in v1.1.0:** You can ask Tailscale to advertise additional routes beyond the VPC (for example, if you want to [route specific Internet hosts though the subnet router](https://tailscale.com/kb/1059/ip-blocklist-relays/#using-tailscale-to-improve-on-ip-block-lists)). Just use the "additional_routes" variable:

```
additional_routes = ["8.8.8.8/32", "8.8.4.4/32"]
```

## Q&A

**Why are subnet ids required? Can't the module determine the subnet ids automatically?**

Yes, but if you are deploying your own VPC as part of the same configuration, depending on the subnet ids there is the cleanest way to make sure the subnets are provisioned before the router.

## Thanks

Thanks to David Norton for writing [Run a Tailscale VPN relay on ECS/Fargate](https://platformers.dev/log/2022/tailscale-ecs/), which inspired this module. Today, we're able to create containers based on the unmodified [official Tailscale image](https://hub.docker.com/r/tailscale/tailscale) instead of having to create our own images, which simplifies this process quite a bit.
