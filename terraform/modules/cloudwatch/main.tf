resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.name_prefix}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = var.cpu_threshold_high
  alarm_description   = "Alarm when CPU exceeds threshold"
  alarm_actions       = [aws_sns_topic.cpu_alerts.arn, var.scale_out_policy_arn, var.alarm_topic_arn]
  dimensions = {
    AutoScalingGroupName = var.asg_name
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.name_prefix}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = var.cpu_threshold_low
  alarm_description   = "Alarm when CPU goes below threshold"
  alarm_actions       = [aws_sns_topic.cpu_alerts.arn, var.scale_in_policy_arn, var.alarm_topic_arn]
  dimensions = {
    AutoScalingGroupName = var.asg_name
  }
}

resource "aws_sns_topic" "cpu_alerts" {
  name = "${var.name_prefix}-cpu-alerts"
}
