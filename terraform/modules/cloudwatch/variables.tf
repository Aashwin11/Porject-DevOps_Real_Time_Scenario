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

variable "scale_out_policy_arn" {
  description = "Auto Scaling Group scale-out policy ARN"
  type        = string
}

variable "scale_in_policy_arn" {
  description = "Auto Scaling Group scale-in policy ARN"
  type        = string
}

variable "alarm_topic_arn" {
    type=string
}