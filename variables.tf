variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "domain_names" {
  description = "Domains to register and host in Route 53 (e.g. [\"njnode.com\"]) — list more than one only during a migration overlap window, one hosted zone + registration per entry"
  type        = set(string)
}

variable "admin_ip_cidr" {
  description = "Your IP address in CIDR notation (e.g. 1.2.3.4/32) — the only source allowed to SSH into the instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_public_key" {
  description = "Public key contents (e.g. cat ~/.ssh/id_ed25519.pub) for the EC2 key pair Terraform will create"
  type        = string
}

variable "monthly_budget_usd" {
  description = "Monthly AWS cost budget threshold in USD, used for alerts and the auto-stop Budget Action"
  type        = number
  default     = 20
}

variable "budget_alert_email" {
  description = "Email address that receives AWS Budget alert notifications"
  type        = string
}

# ICANN requires registrant, admin, and tech contact info for domain
# registration. Reusing the same contact for all three roles — that's the
# normal case for a personal/solo-owned domain.
variable "domain_contact" {
  description = "ICANN contact information for domain registration (registrant/admin/tech)"
  type = object({
    first_name        = string
    last_name         = string
    organization_name = optional(string, "")
    address_line_1    = string
    city               = string
    state              = string
    country_code       = string
    zip_code            = string
    phone_number        = string
    email               = string
  })
  sensitive = true
}
