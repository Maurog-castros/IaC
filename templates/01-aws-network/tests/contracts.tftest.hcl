mock_provider "aws" {
  mock_data "aws_region" { defaults = { region = "us-east-1" } }
}
run "private_network" {
  command = apply
  assert {
    condition     = length(output.private_subnets) == 2
    error_message = "La red debe conservar dos dominios de fallo."
  }
}
run "reject_single_zone" {
  command = plan
  variables { zones = { a = "us-east-1a" } }
  expect_failures = [var.zones]
}
run "module_isolation" {
  command = plan
  module { source = "./modules/network" }
  variables {
    name  = "contract"
    cidr  = "10.42.0.0/16"
    zones = { a = "us-east-1a", b = "us-east-1b" }
  }
  assert {
    condition     = alltrue([for subnet in aws_subnet.private : !subnet.map_public_ip_on_launch]) && length(aws_default_security_group.deny.ingress) == 0 && length(aws_default_security_group.deny.egress) == 0
    error_message = "Subredes sin IP pública y default SG cerrado."
  }
  assert {
    condition     = aws_subnet.private["a"].cidr_block == "10.42.0.0/24" && aws_subnet.private["b"].cidr_block == "10.42.1.0/24"
    error_message = "CIDR debe ser determinista y sin solapamientos."
  }
}
