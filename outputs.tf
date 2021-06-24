# VPC
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

# Subnets
output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}
output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}
output "intra_subnets" {
  description = "List of IDs of bastion subnets"
  value       = module.vpc.intra_subnets
}

# NAT gateways
output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = module.vpc.nat_public_ips
}

# Customer Gateway
output "cgw_ids" {
  description = "List of IDs of Customer Gateway"
  value       = module.vpc.cgw_ids
}

# Security Group
output "public_subnet_sg_id" {
  description = "The ID of the security group"
  value       = module.public_subnet_sg.security_group_id
}
output "public_subnet_sg_name" {
  description = "The name of the security group"
  value       = module.public_subnet_sg.security_group_name
}
output "private_subnet_sg_id" {
  description = "The ID of the security group"
  value       = module.private_subnet_sg.security_group_id
}
output "private_subnet_sg_name" {
  description = "The name of the security group"
  value       = module.private_subnet_sg.security_group_name
}
output "database_sg_id" {
  description = "The ID of the security group"
  value       = module.database_sg.security_group_id
}
output "database_sg_name" {
  description = "The name of the security group"
  value       = module.database_sg.security_group_name
}

# S3

output "s3_log_bucket" {
  description = "The name of the bucket."
  value       = module.s3_log_bucket.s3_bucket_id
}

#EC2

output "ec2-public-az1" {
  description = "ID de EC2."
  value       = module.ec2-public-az1.id  
}
output "ec2-public-az2" {
  description = "ID de EC2."
  value       = module.ec2-public-az2.id  
}
output "ec2-private-az1" {
  description = "ID de EC2."
  value       = module.ec2-private-az1.id  
}
output "ec2-intra" {
  description = "ID de EC2."
  value       = module.ec2-intra.id  
}


#RDS

output "db_instance_name" {
  description = "The database name"
  value       = module.db-rds.db_instance_name
}
output "db_instance_username" {
  description = "The master username for the database"
  value       = module.db-rds.db_instance_username
  sensitive   = true
}
