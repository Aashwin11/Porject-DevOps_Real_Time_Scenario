data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "incident-handler-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "lambda_policy_doc" {
  statement {
    actions = [
      "ec2:RunInstances",
      "ec2:DescribeInstances",
      "ec2:TerminateInstances",
      "ec2:CreateTags",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:DescribeTargetGroups"
    ]
    resources = ["*"]
  }
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "incident-handler-policy"
  description = "Permissions for Lambda to manage EC2 and ALB"
  policy      = data.aws_iam_policy_document.lambda_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "incident_handler" {
  function_name = "incident-handler"
  filename      = "${path.module}/lambda_code/incident_handler.zip"
  handler       = "incident_handler.handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda_role.arn

  environment {
    variables = {
      AMI_ID           = var.ami_id
      SG_ID            = var.sg_id
      SUBNET_IDS       = join(",", var.subnet_ids)
      TARGET_GROUP_ARN = var.target_group_arn
      USER_DATA        = filebase64("${path.module}/lambda_code/user_data.sh")
    }
  }
}

resource "aws_sns_topic" "alarm_topic" {
  name = "alarm-notification-topic"
}

resource "aws_sns_topic_subscription" "lambda_sub" {
  topic_arn = aws_sns_topic.alarm_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.incident_handler.arn
}

resource "aws_lambda_permission" "sns_invoke" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.incident_handler.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alarm_topic.arn
}