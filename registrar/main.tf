terraform {
  required_providers {
    namecheap = {
      source  = "namecheap/namecheap"
      version = ">= 2.0.0"
    }
  }
}

variable "namecheap_user" {
  type    = string
  default = "bvzzdesign"
}

variable "namecheap_api_key" {
  type      = string
  sensitive = true
}

provider "namecheap" {
  user_name   = var.namecheap_user
  api_user    = var.namecheap_user
  api_key     = var.namecheap_api_key
  use_sandbox = false
}

data "terraform_remote_state" "dns" {
  backend = "s3"
  config = {
    bucket = "r33drichards-dns-tfstate-390825964154"
    key    = "dns/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "namecheap_domain_records" "domain" {
  for_each    = data.terraform_remote_state.dns.outputs.delegation_nameservers
  domain      = each.key
  mode        = "OVERWRITE"
  nameservers = each.value
}
