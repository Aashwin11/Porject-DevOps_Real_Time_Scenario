output "asg_name" {
  value = aws_autoscaling_group.spot_sim_asg.name
}

output "instance_sg_id"{
  value=aws_launch_template.spot_sim.vpc_security_group_ids
}