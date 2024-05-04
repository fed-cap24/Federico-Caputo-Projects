# AWS provider version definition
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.24.0"
    }
  }

  backend "s3" {
    bucket  = "ecs-modular-plantilla-prueba"
    key     = "terraform.tfstate"
    region  = "us-east-1"
    profile = ""
  }
}

# Configure the AWS Provider
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = var.project-tags
  }
}