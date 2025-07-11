resource "aws_security_group" "alb_sg" {
  name        = "${var.name_prefix}-alb-sg"
  description = "Allow HTTP inbound to ALB"
  vpc_id      = var.vpc_id

  ingress {
    description      = "HTTP from anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-alb-sg"
  }
}

resource "aws_security_group" "instance_sg" {
  name        = "${var.name_prefix}-instance-sg"
  description = "Allow HTTP from ALB"
  vpc_id      = var.vpc_id

  ingress {
    description      = "HTTP from ALB"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    security_groups  = [aws_security_group.alb_sg.id]
  }
  
  
  ingress {
    description      = "HTTP from ALB"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks=["0.0.0.0/0"]
  }
  
  ingress {
    description      = "SSH from ALB"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks=["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-instance-sg"
  }
}
