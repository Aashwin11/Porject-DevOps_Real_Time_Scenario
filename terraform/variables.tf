variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "demo"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "ami_id" {
  description = "AMI ID for instances"
  type        = string
  default     = "ami-0c02fb55956c7d316" # Amazon Linux 2 AMI in us-east-1 (update if needed)
}

variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "t2.micro"
}

variable "max_size" {
  description = "ASG max size"
  type        = number
  default     = 3
}

variable "min_size" {
  description = "ASG min size"
  type        = number
  default     = 1
}

variable "desired_capacity" {
  description = "ASG desired capacity"
  type        = number
  default     = 1
}

variable "cpu_threshold_high" {
  description = "CPU high threshold for CloudWatch alarm"
  type        = number
  default     = 70
}

variable "cpu_threshold_low" {
  description = "CPU low threshold for CloudWatch alarm"
  type        = number
  default     = 30
}
