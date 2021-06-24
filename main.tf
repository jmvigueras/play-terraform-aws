provider "aws" {
  profile = "default"
  region = local.region
}
locals {
  region = "eu-west-2"
}

################################################################################
# VPC Module
################################################################################

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "ingress-vpc"
  cidr = "10.20.0.0/20"

  azs              = ["${local.region}a", "${local.region}b"]
  private_subnets  = ["10.20.2.0/24", "10.20.4.0/24"]
  public_subnets   = ["10.20.1.0/24", "10.20.3.0/24"]
  intra_subnets    = ["10.20.0.0/24"]
  database_subnets = ["10.20.10.0/24", "10.20.11.0/24"]

  enable_ipv6 = false

  manage_default_route_table = true
  default_route_table_tags   = { DefaultRouteTable = true }

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = false
  single_nat_gateway = false

  customer_gateways = {
        IP1 = {
        bgp_asn    = 65112
        ip_address = "83.36.106.149"
        }
    }

  enable_vpn_gateway = true

  tags = {
    Owner       = "terraform-test"
    Environment = "test-terraform-deploy"
  }

  vpc_tags = {
    Name = "ingress-vpc-10.20.0.0_20"
  }
}

################################################################################
# Security Group Module
################################################################################

module "public_subnet_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "allow-80-http-source-all"
  description = "SG para habilitar trafico HTTP"
  vpc_id      =  module.vpc.vpc_id
  
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "all-icmp"]
  egress_rules        = ["all-all"]

  tags = {  
    Owner       = "terraform-test"
    Environment = "test-terraform-deploy"
  }
}

module "private_subnet_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "allow-traffic-private-subnet"
  description = "SG para habilitar trafico private subnet"
  vpc_id      =  module.vpc.vpc_id
  
  ingress_cidr_blocks = ["10.20.0.0/20", "192.168.20.0/24"]
  ingress_rules       = ["http-80-tcp", "ssh-tcp", "all-icmp"]
  egress_rules        = ["all-all"]

  tags = {  
    Owner       = "terraform-test"
    Environment = "test-terraform-deploy"
  }
}

module "intra_subnet_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "allow-22-SSH-source-all"
  description = "SG para habilitar trafico SSH a subnet bastion"
  vpc_id      =  module.vpc.vpc_id
  
  ingress_cidr_blocks = ["10.20.0.0/20", "192.168.20.0/24", "83.36.106.149/32"]
  ingress_rules       = ["ssh-tcp", "all-icmp"]
  egress_rules        = ["all-all"]

  tags = {  
    Owner       = "terraform-test"
    Environment = "test-terraform-deploy"
  }
}

module "database_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4"

  name        = "allow-3306-mysql-source-public-net"
  description = "Complete MySQL example security group"
  vpc_id      = module.vpc.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "MySQL access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]

  tags = {  
    Owner       = "terraform-test"
    Environment = "test-terraform-deploy"
  }
}

################################################################################
# S3 Module
################################################################################

module "s3_log_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket                                = "logs-elb-${random_pet.this.id}"
  acl                                   = "log-delivery-write"
  force_destroy                         = true
  attach_elb_log_delivery_policy        = true
  attach_lb_log_delivery_policy         = true
  attach_deny_insecure_transport_policy = true
}

################################################################################
# Extra resources
################################################################################

resource "random_pet" "this" {
  length = 2
}

################################################################################
# EC2 Module
################################################################################

module "ec2-public-az1" {
  source = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 2.0"

  instance_count = 1

  name                   = "srv-az1-public-ingress-vpc"
  ami                    = "ami-0b2a43be9744bcf11"
  instance_type          = "t2.micro"
  key_name               = "ingress-test-terraform-eu-west-2"
  monitoring             = true
  vpc_security_group_ids = [module.public_subnet_sg.security_group_id]
  subnet_id              = tolist(module.vpc.public_subnets)[0]
  associate_public_ip_address = false

  tags = {  
    Owner       = "terraform-test"
    Environment = "test-terraform-deploy"
  }
}

module "ec2-public-az2" {
  source = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 2.0"

  instance_count = 1

  name                   = "srv-az2-public-ingress-vpc"
  ami                    = "ami-0b2a43be9744bcf11"
  instance_type          = "t2.micro"
  key_name               = "ingress-test-terraform-eu-west-2"
  monitoring             = true
  vpc_security_group_ids = [module.public_subnet_sg.security_group_id]
  subnet_id              = tolist(module.vpc.public_subnets)[1]
  associate_public_ip_address = false

  tags = {  
    Owner       = "terraform-test"
    Environment = "test-terraform-deploy"
  }
}

module "ec2-private-az1" {
  source = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 2.0"

  instance_count = 1

  name                   = "srv-az1-private-ingress-vpc"
  ami                    = "ami-0b2a43be9744bcf11"
  instance_type          = "t2.micro"
  key_name               = "ingress-test-terraform-eu-west-2"
  monitoring             = true
  vpc_security_group_ids = [module.private_subnet_sg.security_group_id]
  subnet_id              = tolist(module.vpc.private_subnets)[0]
  associate_public_ip_address = false

  tags = {
    Owner       = "terraform-test"
    Environment = "test-terraform-deploy"
  }
}

module "ec2-intra" {
  source = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 2.0"

  instance_count = 1

  name                   = "srv-intra-ingress-vpc"
  ami                    = "ami-0b2a43be9744bcf11"
  instance_type          = "t2.micro"
  key_name               = "ingress-test-terraform-eu-west-2"
  monitoring             = true
  vpc_security_group_ids = [module.intra_subnet_sg.security_group_id]
  subnet_id              = tolist(module.vpc.intra_subnets)[0]
  associate_public_ip_address = true

  tags = {
    Owner       = "terraform-test"
    Environment = "test-terraform-deploy"
  }
}



################################################################################
# ELB
################################################################################

module "elb-public" {
  source = "terraform-aws-modules/elb/aws"

  name = "elb-front-public"

  subnets         = module.vpc.public_subnets
  security_groups = [module.public_subnet_sg.security_group_id]
  internal        = false

  listener = [
    {
      instance_port     = "80"
      instance_protocol = "http"
      lb_port           = "80"
      lb_protocol       = "http"
    },
  ]

  health_check = {
    target              = "HTTP:80/"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }

  access_logs = {
    bucket = module.s3_log_bucket.s3_bucket_id
  }

  tags = {
    Owner         = "terraform-test"
    Environment   = "test-terraform-deploy"
  }

  # ELB attachments
  number_of_instances = 2
  instances           = [module.ec2-public-az1.id[0], module.ec2-public-az2.id[0]]
}

module "elb-private" {
  source = "terraform-aws-modules/elb/aws"

  name = "elb-front-private"

  subnets         = module.vpc.private_subnets
  security_groups = [module.private_subnet_sg.security_group_id]
  internal        = false

  listener = [
    {
      instance_port     = "3306"
      instance_protocol = "TCP"
      lb_port           = "3306"
      lb_protocol       = "TCP"
    },
  ]

  health_check = {
    target              = "TCP:3306"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }

  access_logs = {
    bucket = module.s3_log_bucket.s3_bucket_id
  }

  # ELB attachments
  number_of_instances = 1
  instances           = [module.ec2-private-az1.id[0]]

  tags = {
    Owner         = "terraform-test"
    Environment   = "test-terraform-deploy"
  }
}

################################################################################
# RDS
################################################################################

module "db-rds" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "terraformmysqldb"

  create_db_option_group    = false
  create_db_parameter_group = false

  engine               = "mysql"
  engine_version       = "8.0.20"
  family               = "mysql8.0" # DB parameter group
  major_engine_version = "8.0"      # DB option group
  instance_class       = "db.t2.micro"

  allocated_storage = 20

  name                   = "mysqlterraform"
  username               = "usermysqltest"
  password               = "VANq7FkCTGNptsQaTJ"
  port                   = 3306

  subnet_ids             = module.vpc.database_subnets
  vpc_security_group_ids = [module.database_sg.security_group_id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  backup_retention_period = 0

  tags = {
    Owner         = "terraform-test"
    Environment   = "test-terraform-deploy"
  }
}
