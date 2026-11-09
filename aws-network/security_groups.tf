resource "aws_security_group" "web" {
  count       = var.enable_wordpress_lab ? 1 : 0
  name_prefix = "${local.name_prefix}-web-"
  description = "WordPress and SSH jump host"
  vpc_id      = aws_vpc.this.id
  tags        = { Name = "${local.name_prefix}-web-sg" }
}

resource "aws_security_group" "db" {
  count       = var.enable_wordpress_lab ? 1 : 0
  name_prefix = "${local.name_prefix}-db-"
  description = "Private MariaDB host"
  vpc_id      = aws_vpc.this.id
  tags        = { Name = "${local.name_prefix}-db-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "web_ssh" {
  count             = var.enable_wordpress_lab ? 1 : 0
  security_group_id = aws_security_group.web[0].id
  description       = "Admin SSH access"
  cidr_ipv4         = var.admin_cidr
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "web_http" {
  count             = var.enable_wordpress_lab ? 1 : 0
  security_group_id = aws_security_group.web[0].id
  description       = "Lab HTTP - restricted to admin IP; no sensitive data"
  cidr_ipv4         = var.admin_cidr
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "web_proxy" {
  count                        = var.enable_wordpress_lab ? 1 : 0
  security_group_id            = aws_security_group.web[0].id
  description                  = "APT proxy from DB instance only"
  referenced_security_group_id = aws_security_group.db[0].id
  ip_protocol                  = "tcp"
  from_port                    = 3128
  to_port                      = 3128
}

resource "aws_vpc_security_group_ingress_rule" "db_ssh" {
  count                        = var.enable_wordpress_lab ? 1 : 0
  security_group_id            = aws_security_group.db[0].id
  description                  = "SSH via web jump host"
  referenced_security_group_id = aws_security_group.web[0].id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
}

resource "aws_vpc_security_group_ingress_rule" "db_mariadb" {
  count                        = var.enable_wordpress_lab ? 1 : 0
  security_group_id            = aws_security_group.db[0].id
  description                  = "MariaDB reachable from web only"
  referenced_security_group_id = aws_security_group.web[0].id
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
}

resource "aws_vpc_security_group_egress_rule" "web_all" {
  count             = var.enable_wordpress_lab ? 1 : 0
  security_group_id = aws_security_group.web[0].id
  description       = "Internet apt and DB"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "db_all" {
  count             = var.enable_wordpress_lab ? 1 : 0
  security_group_id = aws_security_group.db[0].id
  description       = "VPC private routing; no external default route"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
