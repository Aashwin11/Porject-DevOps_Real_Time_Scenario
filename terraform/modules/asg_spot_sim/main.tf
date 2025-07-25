resource "aws_launch_template" "spot_sim" {
  name_prefix            = "${var.name_prefix}-spot-sim"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [var.instance_sg_id]
  user_data              = base64encode(file("${path.module}/ubuntu-user-data.sh"))

  monitoring {
    enabled = true
  }

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

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 90
      instance_warmup        = 300
    }
  }

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
# Scaling Policy that increases desired capacity by 1 when triggered
resource "aws_autoscaling_policy" "scale_out" {
  name = "${var.name_prefix}-scale-out-policy"
  autoscaling_group_name = aws_autoscaling_group.spot_sim_asg.name
  scaling_adjustment = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 30

}

# Scaling Policy that decreases desired capacity by 1 when triggered
resource "aws_autoscaling_policy" "scale_in" {
  name                   = "${var.name_prefix}-scale-in-policy"
  autoscaling_group_name = aws_autoscaling_group.spot_sim_asg.name
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 30
}