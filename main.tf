terraform {
  required_version = ">= 1.10, < 2.0"

  backend "s3" {
    bucket       = "r33drichards-dns-tfstate-390825964154"
    key          = "dns/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.aws_region
}

locals {
  robw_fyi = {
    domain_name = "robw.fyi"
    target_ip   = "35.185.44.232"
  }
  flakery_xyz = {
    domain_name = "flakery.xyz"
    target_ip   = "34.136.75.13"
  }
}

