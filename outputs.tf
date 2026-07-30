output "instance_public_ip" {
  description = "Elastic IP of the ThreatForge EC2 instance"
  value       = aws_eip.threatforge.public_ip
}

output "threatforge_url" {
  description = "URL the ThreatForge web app will be reachable at, once built"
  value       = "https://${var.subdomain}.${var.domain_name}"
}

output "route53_name_servers" {
  description = "Route 53 nameservers for the hosted zone — should match what's set on the domain registration"
  value       = aws_route53_zone.main.name_servers
}

output "ssh_command" {
  description = "SSH command to connect to the instance directly (bypassing the Cloudflare Tunnel, which is for aiserver, not this instance)"
  value       = "ssh -i <path-to-private-key> ubuntu@${aws_eip.threatforge.public_ip}"
}
