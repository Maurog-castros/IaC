terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }
}
variable "name" { type = string }
variable "zones" { type = map(string) }
variable "cidr" {
  type = string
  validation {
    condition     = can(cidrsubnet(var.cidr, 8, 15))
    error_message = "CIDR IPv4 debe permitir subredes con ocho bits adicionales."
  }
}
locals {
  indexes = { for index, key in sort(keys(var.zones)) : key => index }
}
resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = var.name }
}
resource "aws_default_security_group" "deny" {
  vpc_id  = aws_vpc.this.id
  ingress = []
  egress  = []
  tags    = { Name = "${var.name}-default-deny" }
}
resource "aws_subnet" "private" {
  for_each                = var.zones
  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value
  cidr_block              = cidrsubnet(var.cidr, 8, local.indexes[each.key])
  map_public_ip_on_launch = false
  tags                    = { Name = "${var.name}-private-${each.key}" }
}
resource "aws_route_table" "private" {
  for_each = var.zones
  vpc_id   = aws_vpc.this.id
  tags     = { Name = "${var.name}-${each.key}" }
}
resource "aws_route_table_association" "private" {
  for_each       = var.zones
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [for table in aws_route_table.private : table.id]
}
data "aws_region" "current" {}
output "vpc_id" { value = aws_vpc.this.id }
output "private_subnets" { value = { for key, subnet in aws_subnet.private : key => subnet.id } }
