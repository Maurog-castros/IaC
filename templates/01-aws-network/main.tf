variable "region" {
  type    = string
  default = "us-east-1"
}
variable "name" {
  type    = string
  default = "iac-network"
}
variable "zones" {
  type    = map(string)
  default = { a = "us-east-1a", b = "us-east-1b" }
  validation {
    condition     = length(var.zones) >= 2 && length(var.zones) <= 4 && length(distinct(values(var.zones))) == length(var.zones)
    error_message = "Use entre dos y cuatro zonas distintas."
  }
}
module "network" {
  source = "./modules/network"
  name   = var.name
  zones  = var.zones
  cidr   = "10.42.0.0/16"
}
output "vpc_id" { value = module.network.vpc_id }
output "private_subnets" { value = module.network.private_subnets }
