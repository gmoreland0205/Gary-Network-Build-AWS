# Reference to Bastion Host Security Group
output "Region" {
  value = var.region
}

output "Availabillity_Zones" {
  value = module.vpc.azs
}

output "Public_Subnets" {
  value = module.vpc.public_subnets
}

output "Private_Subnets" {
  value = module.vpc.private_subnets
}