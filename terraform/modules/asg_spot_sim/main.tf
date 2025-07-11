resource "aws_launch_template" "spot_sim" {
  name_prefix   = "${var.name_prefix}-spot-sim-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  user_data = file("${path.module}/ubuntu-user-data.sh")
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "acting_spot_instance"
      Role = "acting_spot"
    }
  }
}

resource "aws_autoscaling_group" "spot_sim_asg" {
  name                      = "${var.name_prefix}-spot-sim-asg"
  max_size                  = var.max_size
  min_size                  = var.min_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.subnet_ids
  launch_template {
    id      = aws_launch_template.spot_sim.id
    version = "$Latest"
  }
  target_group_arns         = [var.target_group_arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300
 tag {
    key                 = "Name"
    value               = "acting_spot_instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Role"
    value               = "acting_spot"
    propagate_at_launch = true
  }
}
