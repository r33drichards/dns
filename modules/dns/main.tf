terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Route 53 Zone
resource "aws_route53_zone" "domain" {
  name = var.domain_name
}

