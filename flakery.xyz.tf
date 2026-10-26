module "flakery_xyz_dns" {
  source = "./modules/dns"

  domain_name = local.flakery_xyz.domain_name
}

# DNS Records
resource "aws_route53_record" "www_flakery_xyz" {
  zone_id = module.flakery_xyz_dns.zone_id
  name    = "www.${local.flakery_xyz.domain_name}"
  type    = "A"
  ttl     = 300
  records = [local.flakery_xyz.target_ip]
}

resource "aws_route53_record" "root_flakery_xyz" {
  zone_id = module.flakery_xyz_dns.zone_id
  name    = local.flakery_xyz.domain_name
  type    = "A"
  ttl     = 300
  records = [local.flakery_xyz.target_ip]
}

# kc.flakery.xyz
resource "aws_route53_record" "kc_flakery_xyz" {
  zone_id = module.flakery_xyz_dns.zone_id
  name    = "kc.${local.flakery_xyz.domain_name}"
  type    = "A"
  ttl     = 300
  records = [local.flakery_xyz.target_ip]
}

# saphira -> 44.229.214.242
resource "aws_route53_record" "eragon_flakery_xyz" {
  zone_id = module.flakery_xyz_dns.zone_id
  name    = "eragon.${local.flakery_xyz.domain_name}"
  type    = "A"
  ttl     = 300
  records = ["52.40.253.4"]
}

resource "aws_route53_record" "grafana_flakery_xyz" {
  zone_id = module.flakery_xyz_dns.zone_id
  name    = "grafana.${local.flakery_xyz.domain_name}"
  type    = "A"
  ttl     = 300
  records = ["44.225.1.5"]
}

resource "aws_route53_record" "crane_flakery_xyz" {
  zone_id = module.flakery_xyz_dns.zone_id
  name    = "crane.${local.flakery_xyz.domain_name}"
  type    = "A"
  ttl     = 300
  records = ["44.225.1.5"]
}

resource "aws_route53_record" "saphira_flakery_xyz" {
  zone_id = module.flakery_xyz_dns.zone_id
  name    = "saphira.${local.flakery_xyz.domain_name}"
  type    = "A"
  ttl     = 300
  records = ["44.225.1.5"]
}

# saphira-gpt 
resource "aws_route53_record" "saphira_gpt_flakery_xyz" {
  zone_id = module.flakery_xyz_dns.zone_id
  name    = "saphira-gpt.${local.flakery_xyz.domain_name}"
  type    = "A"
  ttl     = 300
  records = ["44.225.1.5"]
}


resource "aws_route53_record" "auth_flakery_xyz" {
  zone_id = module.flakery_xyz_dns.zone_id
  name    = "auth.${local.flakery_xyz.domain_name}"
  type    = "A"
  ttl     = 300
  records = ["44.240.105.96"]
}

resource "aws_route53_record" "jaapi_flakery_xyz" {
  zone_id = module.flakery_xyz_dns.zone_id
  name    = "jaapi.${local.flakery_xyz.domain_name}"
  type    = "A"
  ttl     = 300
  records = ["35.87.11.226"]
}

resource "aws_route53_record" "ja_flakery_xyz" {
  zone_id = module.flakery_xyz_dns.zone_id
  name    = "ja.${local.flakery_xyz.domain_name}"
  type    = "A"
  ttl     = 300
  records = ["35.87.11.226"]
}