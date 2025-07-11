variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "asg_name" {
  description = "Name of the Auto Scaling Group"
  type        = string
}

variable "cpu_threshold_high" {
  description = "CPU utilization high threshold"
  type        = number
  default     = 70
}

variable "cpu_threshold_low" {
  description = "CPU utilization low threshold"
  type        = number
  default     = 30
}
