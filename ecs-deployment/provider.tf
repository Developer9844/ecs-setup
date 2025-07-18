terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.99"
    }
  }
}

provider "aws" {
  profile = var.aws_profile
  region  = var.region
}
