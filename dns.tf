resource "aws_route53_zone" "main" {
  for_each = var.domain_names
  name     = each.value
  comment  = "Managed by Terraform — vuln-skill-cloud"
}

# Retired 2026-08-01 -- was aws_route53_record.threatforge, superseded by
# vuln-skill below. Verified working end-to-end (DNS resolved, TLS cert
# issued, nginx serving it, app responding correctly) before this was
# removed. Kept as a comment, not deleted outright, so the cutover
# decision and its timing are visible in history rather than silently gone.

resource "aws_route53_record" "vuln_skill" {
  for_each = var.domain_names
  zone_id  = aws_route53_zone.main[each.value].zone_id
  name     = "vulnskill.${each.value}"
  type     = "A"
  ttl      = 300
  records  = [module.compute.public_ip]
}

# soc-skill-cloud moved 2026-08-07 off this shared instance onto its own
# independent one (../../../soc-skill/repo/infra) so either app can be destroyed
# without affecting the other. Its EIP is read via remote state rather
# than hardcoded, since it's a genuinely separate Terraform project/state
# now - this only resolves once soc-skill-infra has been applied at least
# once (its state file has to exist first).
data "terraform_remote_state" "soc_skill" {
  backend = "local"
  config = {
    path = "../../../soc-skill/repo/infra/terraform.tfstate"
  }
}

resource "aws_route53_record" "socskill" {
  for_each = var.domain_names
  zone_id  = aws_route53_zone.main[each.value].zone_id
  name     = "socskill.${each.value}"
  type     = "A"
  ttl      = 300
  records  = [data.terraform_remote_state.soc_skill.outputs.public_ip]
}
