output "vpc_id" {
  description = "Created VPC ID."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "VPC IPv4 CIDR."
  value       = aws_vpc.this.cidr_block
}

output "internet_gateway_id" {
  description = "Internet Gateway ID."
  value       = aws_internet_gateway.this.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs by index."
  value       = { for k, v in aws_subnet.public : k => v.id }
}

output "private_subnet_ids" {
  description = "Private subnet IDs by index."
  value       = { for k, v in aws_subnet.private : k => v.id }
}

output "public_route_table_id" {
  description = "Public route table ID."
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "Private route table IDs by index."
  value       = { for k, v in aws_route_table.private : k => v.id }
}

output "web_public_ip" {
  description = "WordPress public IP (lab only)."
  value       = try(aws_instance.web[0].public_ip, null)
}
output "web_private_ip" {
  description = "WordPress private IP (lab only)."
  value       = try(aws_instance.web[0].private_ip, null)
}
output "db_private_ip" {
  description = "MariaDB private IP (lab only)."
  value       = try(aws_instance.db[0].private_ip, null)
}
