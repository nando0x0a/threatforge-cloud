# EC2 + security group + budget, extracted 2026-08-07 into the shared
# ../../../modules/app-ec2-stack module when soc-skill-cloud got its own
# independent instance (../../../soc-skill/repo/infra) instead of sharing this one.
#
# The `moved` blocks below tell Terraform these resources didn't get
# destroyed and recreated, just renamed to their module-qualified
# addresses - required since this instance is LIVE, serving real traffic.
# Applied 2026-08-07 (njnode.com DNS propagation finished) - live AWS
# state already reflects the module-qualified addresses; these blocks are
# now no-ops kept for history/documentation rather than load-bearing.
module "compute" {
  source = "../../../modules/app-ec2-stack"

  # Renamed from "threatforge" 2026-08-07, at NJ's explicit request ("i do
  # not need a maintenance window, you can change them now") - a
  # deliberate, accepted destroy+recreate of the then-live instance/
  # security group/key pair/IAM role, not an accident. Went through two
  # naming attempts same day: first "vuln-skill" (app-branded), then NJ
  # asked for general/non-app-branded infra names instead ("only use
  # labels/names for specific apps when related to the apps themselves"),
  # landing on "cloud-vuln" - infra plumbing names stay general, app-
  # specific names (DNS hostnames, Docker container names) are untouched.
  # Root volume encryption enabled at the same time since the instance was
  # being rebuilt anyway (zero extra downtime cost bundled into the one
  # rebuild).
  app_name                   = "cloud-vuln"
  security_group_description = "cloud-vuln instance - SSH from admin IP only, HTTPS from anywhere, no other inbound"
  # No budget_name override (as of 2026-08-07) -- was "vuln-skill-cloud-monthly"
  # (the pre-"cloud-vuln"-convention app-branded name, kept via override
  # since AWS Budget names are immutable and changing it forces a
  # destroy+recreate of the budget + its auto-stop action). NJ opted into
  # that destroy+recreate to match soc-skill-cloud's already-consistent
  # "cloud-soc-monthly" naming -- now defaults to "cloud-vuln-monthly"
  # same as soc-skill-cloud defaults to "cloud-soc-monthly".
  encrypt_root_volume        = true
  # Name TAG (console display only, not a resource identity) stays
  # app-specific - NJ set this by hand via the AWS console 2026-08-07
  # right after the app_name rename above; captured here so the next
  # `plan` doesn't revert it back to "cloud-vuln".
  resource_name_tag = "vuln-skill"
  aws_region                 = var.aws_region
  admin_ip_cidr              = var.admin_ip_cidr
  instance_type              = var.instance_type
  key_pair_public_key        = var.key_pair_public_key
  monthly_budget_usd         = var.monthly_budget_usd
  budget_alert_email         = var.budget_alert_email

  # Bootstraps Docker + git so the instance is ready for `git clone` +
  # `./setup.sh` - deliberately NOT auto-running Vuln-Skill's own setup,
  # since that prompts interactively for API keys.
  user_data = <<-EOF
    #!/usr/bin/env bash
    set -euo pipefail
    apt-get update -y
    apt-get install -y git ca-certificates curl
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    usermod -aG docker ubuntu
  EOF
}

moved {
  from = aws_security_group.threatforge
  to   = module.compute.aws_security_group.this
}

moved {
  from = aws_key_pair.threatforge
  to   = module.compute.aws_key_pair.this
}

moved {
  from = aws_instance.threatforge
  to   = module.compute.aws_instance.this
}

moved {
  from = aws_eip.threatforge
  to   = module.compute.aws_eip.this
}

moved {
  from = aws_budgets_budget.monthly
  to   = module.compute.aws_budgets_budget.monthly
}

moved {
  from = aws_iam_role.budget_action
  to   = module.compute.aws_iam_role.budget_action
}

moved {
  from = aws_iam_role_policy_attachment.budget_action
  to   = module.compute.aws_iam_role_policy_attachment.budget_action
}

moved {
  from = aws_budgets_budget_action.stop_instance
  to   = module.compute.aws_budgets_budget_action.stop_instance
}
