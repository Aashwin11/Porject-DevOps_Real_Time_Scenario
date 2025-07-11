provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source            = "./modules/vpc"
  name_prefix       = var.name_prefix
  vpc_cidr          = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  availability_zones = var.availability_zones
}

module "security_groups" {
  source      = "./modules/security_groups"
  name_prefix = var.name_prefix
  vpc_id      = module.vpc.vpc_id
}

module "alb" {
  source      = "./modules/alb"
  name_prefix = var.name_prefix
  alb_sg_ids  = [module.security_groups.alb_sg_id]
  subnet_ids  = module.vpc.public_subnet_ids
  vpc_id      = module.vpc.vpc_id
}

module "asg_spot_sim" {
  source          = "./modules/asg_spot_sim"
  name_prefix     = var.name_prefix
  ami_id          = var.ami_id
  instance_type   = var.instance_type
  max_size        = var.max_size
  min_size        = var.min_size
  desired_capacity= var.desired_capacity
  subnet_ids      = module.vpc.public_subnet_ids
  target_group_arn= module.alb.target_group_arn
  instance_sg_id  = module.security_groups.instance_sg_id  # <-- Pass the instance SG ID here

}

module "cloudwatch" {
  source           = "./modules/cloudwatch"
  name_prefix      = var.name_prefix
  asg_name         = module.asg_spot_sim.asg_name
  cpu_threshold_high = var.cpu_threshold_high
  cpu_threshold_low  = var.cpu_threshold_low
}
