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
