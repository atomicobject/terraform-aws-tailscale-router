variable "additional_routes" {
  type        = list(string)
  description = "additional routes to advertise (e.g. \"8.8.8.8/32\")"
  default     = []
}

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
  default     = "1.38.4"
}

variable "vpc_id" {
  type        = string
  description = "id of the VPC to launch the router in"
}
