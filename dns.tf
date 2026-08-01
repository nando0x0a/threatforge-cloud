resource "aws_route53_zone" "main" {
  name    = var.domain_name
  comment = "Managed by Terraform — vuln-skill-cloud"
}

# Pending retirement (Vuln-Skill rename) -- kept alive until
# aws_route53_record.vuln_skill below is verified working (new cert issued,
# nginx serving it) so the cutover has zero downtime. Remove this block only
# after that verification, in its own separate apply.
resource "aws_route53_record" "threatforge" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "${var.subdomain}.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_eip.threatforge.public_ip]
}

# New home for the renamed app -- added alongside the old record above
# rather than renaming it in place, since changing an aws_route53_record's
# name always force-replaces it (delete+create), which would drop DNS
# resolution for whatever window exists before a new TLS cert can be issued.
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
