# This is a DEFAULT TERRAFORM.tfvars that is used only for the current simulation
# PLEASE CREATE YOUR OWN TERRAFORM.tfvars

name_prefix        = "blackfriday-demo"
aws_region         = "us-east-1"
vpc_cidr           = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
ami_id             = "ami-020cba7c55df1f615"
instance_type      = "t2.micro"
max_size           = 3
min_size           = 1
desired_capacity   = 1
cpu_threshold_high = 70
cpu_threshold_low  = 30
