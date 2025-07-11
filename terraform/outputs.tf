output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "asg_name" {
  value = module.asg_spot_sim.asg_name
}

output "sns_topic_arn" {
  value = module.cloudwatch.sns_topic_arn
}
