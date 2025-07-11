variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "alb_sg_ids" {
  description = "List of ALB security group IDs"
  type        = list(string)
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}
