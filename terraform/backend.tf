terraform {
  backend "s3" {
    bucket         = "s3-aws-tf-ga-sim"
    key            = "devops-project/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks-proj4"
    encrypt        = true
  }
}
