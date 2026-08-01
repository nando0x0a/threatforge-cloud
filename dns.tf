resource "aws_route53_zone" "main" {
  name    = var.domain_name
  comment = "Managed by Terraform — vuln-skill-cloud"
}

# Retired 2026-08-01 -- was aws_route53_record.threatforge, superseded by
# vuln-skill below. Verified working end-to-end (DNS resolved, TLS cert
# issued, nginx serving it, app responding correctly) before this was
# removed. Kept as a comment, not deleted outright, so the cutover
# decision and its timing are visible in history rather than silently gone.

resource "aws_route53_record" "vuln_skill" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "vulnskill.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_eip.threatforge.public_ip]
}

# soc-skill-cloud reuses this same EC2 instance (cost-saving) on its own
# subdomain — see soc-skill-cloud repo for the app itself.
resource "aws_route53_record" "socskill" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "socskill.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_eip.threatforge.public_ip]
}
