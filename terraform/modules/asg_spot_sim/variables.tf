variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for instances"
  type        = string
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

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "target_group_arn" {
  description = "ALB Target Group ARN"
  type        = string
}

variable "instance_sg_id" {
  description = "Security group ID for instances"
  type        = string
}