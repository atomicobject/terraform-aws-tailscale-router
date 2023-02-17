variable "name" {
  type        = string
  description = "name for the subnet router and associated resources"
}

variable "security_group_ids" {
  type        = list(string)
  description = "ids of the security groups to attach to the router"
}

variable "subnet_ids" {
  type        = list(string)
  description = "ids of subnets to launch the router in"
}

variable "tailscale_auth_key" {
  type        = string
  sensitive   = true
  description = "auth key from <https://login.tailscale.com/admin/settings/keys>; used to initially authenticate the router machine"
}

variable "tailscale_version" {
  type        = string
  description = "Tailscale version to deploy"
  default     = "1.36.1"
}

variable "vpc_id" {
  type        = string
  description = "id of the VPC to launch the router in"
}
