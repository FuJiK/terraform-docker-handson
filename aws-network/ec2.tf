data "aws_ami" "ubuntu" {
  count       = var.enable_wordpress_lab ? 1 : 0
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "web" {
  count                       = var.enable_wordpress_lab ? 1 : 0
  ami                         = data.aws_ami.ubuntu[0].id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public["0"].id
  vpc_security_group_ids      = [aws_security_group.web[0].id]
  associate_public_ip_address = true
  key_name                    = var.ssh_key_name
  user_data                   = file("${path.module}/cloud-init/web-proxy.sh")
  monitoring                  = false

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size_gib
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "${local.name_prefix}-wordpress"
    Role = "web"
  }

  lifecycle {
    precondition {
      condition     = var.ssh_key_name != null && trimspace(coalesce(var.ssh_key_name, "")) != ""
      error_message = "Set ssh_key_name to an existing EC2 SSH key pair."
    }
    precondition {
      condition     = var.admin_cidr != null && var.admin_cidr != "0.0.0.0/0"
      error_message = "Set admin_cidr to your trusted public address /32."
    }
  }
}

resource "aws_instance" "db" {
  count                       = var.enable_wordpress_lab ? 1 : 0
  ami                         = data.aws_ami.ubuntu[0].id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private["0"].id
  vpc_security_group_ids      = [aws_security_group.db[0].id]
  associate_public_ip_address = false
  key_name                    = var.ssh_key_name
  monitoring                  = false

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size_gib
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "${local.name_prefix}-mariadb"
    Role = "db"
  }
}
