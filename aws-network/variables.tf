variable "aws_region" {
  description = "AWS Region in which the lab network is created."
  type        = string
  default     = "ap-northeast-1"
}

variable "project" {
  description = "Project tag and resource naming prefix."
  type        = string
  default     = "aws-network-lab"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC."
  type        = string
  default     = "10.40.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "Two availability zones in aws_region."
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c"]

  validation {
    condition     = length(var.availability_zones) == 2 && length(distinct(var.availability_zones)) == 2
    error_message = "Exactly two distinct availability zones are required."
  }
}

variable "public_subnet_cidrs" {
  description = "Two public subnet IPv4 CIDRs, one per AZ."
  type        = list(string)
  default     = ["10.40.0.0/24", "10.40.1.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) == 2 && alltrue([for c in var.public_subnet_cidrs : can(cidrnetmask(c))])
    error_message = "Provide two valid public subnet IPv4 CIDRs."
  }
}

variable "private_subnet_cidrs" {
  description = "Two isolated private subnet IPv4 CIDRs, one per AZ."
  type        = list(string)
  default     = ["10.40.10.0/24", "10.40.11.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) == 2 && alltrue([for c in var.private_subnet_cidrs : can(cidrnetmask(c))])
    error_message = "Provide two valid private subnet IPv4 CIDRs."
  }
}

variable "enable_wordpress_lab" {
  description = "Opt in to creating two billable EC2 servers."
  type        = bool
  default     = false
}
variable "ssh_key_name" {
  description = "Existing EC2 key pair name; required when lab is enabled."
  type        = string
  default     = null
}
variable "admin_cidr" {
  description = "Trusted IPv4 CIDR (/32) for SSH and initial HTTP access."
  type        = string
  default     = null
  validation {
    condition     = var.admin_cidr == null ? true : (can(cidrnetmask(var.admin_cidr)) && var.admin_cidr != "0.0.0.0/0")
    error_message = "Use a valid restricted IPv4 CIDR; never 0.0.0.0/0."
  }
}
variable "instance_type" {
  type    = string
  default = "t3.micro"
}
variable "root_volume_size_gib" {
  type    = number
  default = 12
  validation {
    condition     = var.root_volume_size_gib >= 8
    error_message = "At least 8 GiB is required."
  }
}
