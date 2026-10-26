output "delegation_nameservers" {
  description = "Set these custom nameservers at the registrar, manually or with the registrar stack."
  value = {
    "robw.fyi"    = module.robw_fyi_dns.nameservers_route53
    "flakery.xyz" = module.flakery_xyz_dns.nameservers_route53
  }
}
