output "instance_public_ip" {
  description = "Elastic IP of this EC2 instance (Vuln-Skill only, as of 2026-08-07 - soc-skill-cloud has its own independent instance, see ../../../soc-skill/repo/infra)"
  value       = module.compute.public_ip
}

output "vuln_skill_urls" {
  description = "URLs the Vuln-Skill web app is reachable at, one per configured domain"
  value       = { for d in var.domain_names : d => "https://vulnskill.${d}" }
}

output "soc_skill_urls" {
  description = "URLs the soc-skill-cloud web app is reachable at, one per configured domain (app itself lives on its own instance, ../../../soc-skill/repo/infra - this project only owns the nando0x0a.com DNS record for it)"
  value       = { for d in var.domain_names : d => "https://socskill.${d}" }
}

output "route53_name_servers" {
  description = "Route 53 nameservers per hosted zone — must match what's set on that domain's registration"
  value       = { for d in var.domain_names : d => aws_route53_zone.main[d].name_servers }
}

output "ssh_command" {
  description = "SSH command to connect to the instance directly (bypassing the Cloudflare Tunnel, which is for aiserver, not this instance)"
  value       = "ssh -i <path-to-private-key> ubuntu@${module.compute.public_ip}"
}
