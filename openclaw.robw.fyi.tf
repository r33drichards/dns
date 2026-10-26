# Authenticated HTTPS/WebSocket gateway for disposable OpenClaw workers.
resource "aws_route53_record" "openclaw" {
  zone_id = module.robw_fyi_dns.zone_id
  name    = "openclaw.${local.robw_fyi.domain_name}"
  type    = "A"
  ttl     = 300
  records = ["45.63.91.217"]
}
