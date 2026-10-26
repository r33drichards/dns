output "nameservers_route53" {
  value       = aws_route53_zone.domain.name_servers
  description = "The nameservers for your domain. Update these in your domain registrar."
}

output "zone_id" {
  value       = aws_route53_zone.domain.zone_id
  description = "The Route53 zone ID for creating DNS records"
} 