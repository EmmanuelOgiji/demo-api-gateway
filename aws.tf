provider "aws" {
  region     = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
  default_tags {
    tags = {
      Name   = var.name,
      Author = "EPO"
    }
  }
}

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.98"
    }
  }
}

