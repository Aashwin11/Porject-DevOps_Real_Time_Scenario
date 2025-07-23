variable "ami_id" {}
variable "sg_id" {}
variable "subnet_ids" { type = list(string) }
variable "target_group_arn" {}
variable "asg_name" {}