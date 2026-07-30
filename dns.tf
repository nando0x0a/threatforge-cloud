resource "aws_route53_zone" "main" {
  name    = var.domain_name
  comment = "Managed by Terraform — threatforge-cloud"
}

resource "aws_route53_record" "threatforge" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "${var.subdomain}.${var.domain_name}"
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
