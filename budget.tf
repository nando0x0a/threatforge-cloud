data "aws_partition" "current" {}

resource "aws_budgets_budget" "monthly" {
  name              = "vuln-skill-cloud-monthly"
  budget_type       = "COST"
  limit_amount      = tostring(var.monthly_budget_usd)
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2026-01-01_00:00"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 50
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.budget_alert_email]
  }
}

# Role the AWS Budgets service assumes to actually execute the stop action.
# Name deliberately kept as "threatforge-cloud-budget-action", not renamed
# with everything else (2026-08-01 Vuln-Skill rename) -- the
# threatforge-terraform IAM user lacks iam:ListInstanceProfilesForRole,
# which the AWS provider needs to safely DELETE a role, so the rename got
# stuck mid-replacement with the auto-stop budget action gone entirely.
# Reverting the name avoids ever needing to delete this role again; it's
# an internal AWS identifier with no user-visible impact either way.
resource "aws_iam_role" "budget_action" {
  name = "threatforge-cloud-budget-action"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "budgets.${data.aws_partition.current.dns_suffix}"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "budget_action" {
  role       = aws_iam_role.budget_action.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AWSBudgetsActions_RolePolicyForResourceAdministrationWithSSM"
}

# Automatically stops the EC2 instance if actual spend crosses 100% of the
# monthly budget. approval_model = AUTOMATIC means this fires without a
# manual confirmation step — this is the real cost cap, not just an alert.
resource "aws_budgets_budget_action" "stop_instance" {
  budget_name         = aws_budgets_budget.monthly.name
  action_type         = "RUN_SSM_DOCUMENTS"
  approval_model      = "AUTOMATIC"
  execution_role_arn  = aws_iam_role.budget_action.arn
  notification_type   = "ACTUAL"

  action_threshold {
    action_threshold_type  = "PERCENTAGE"
    action_threshold_value = 100
  }

  definition {
    ssm_action_definition {
      action_sub_type = "STOP_EC2_INSTANCES"
      instance_ids    = [aws_instance.threatforge.id]
      region          = var.aws_region
    }
  }

  subscriber {
    address           = var.budget_alert_email
    subscription_type = "EMAIL"
  }
}
