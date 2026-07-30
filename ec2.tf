data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "threatforge" {
  name        = "threatforge-cloud"
  description = "ThreatForge cloud instance — SSH from admin IP only, HTTPS from anywhere, no other inbound"

  ingress {
    description = "SSH from admin IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip_cidr]
  }

  ingress {
    description = "HTTPS (web app)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "threatforge" {
  key_name   = "threatforge-cloud"
  public_key = var.key_pair_public_key
}

locals {
  # Bootstraps Docker + git so the instance is ready for `git clone` +
  # `./setup.sh` — deliberately NOT auto-running ThreatForge's own setup,
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

resource "aws_instance" "threatforge" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.threatforge.key_name
  vpc_security_group_ids = [aws_security_group.threatforge.id]
  user_data              = local.user_data

  root_block_device {
    volume_size = 15
    volume_type = "gp3"
  }

  tags = {
    Name = "threatforge-cloud"
  }
}

resource "aws_eip" "threatforge" {
  instance = aws_instance.threatforge.id
  domain   = "vpc"

  tags = {
    Name = "threatforge-cloud"
  }
}
