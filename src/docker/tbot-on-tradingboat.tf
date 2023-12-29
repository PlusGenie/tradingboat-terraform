# Variable definitions
variable "aws_region" {
  description = "AWS region to deploy the resources"
  type        = string
  default     = "eu-west-2"
}

variable "TBOT_DOCKER_BRANCH" {
  description = "Branch name for the IB Gateway Docker repository"
  type        = string
  default     = "master"
}

variable "ami_id" {
  description = "The ID of the AMI to use for the EC2 instance"
  type        = string
  default     = "ami-0e5f882be1900e43b"
}

variable "aws_instance_type" {
  description = "AWS EC2 instances"
  type        = string
  default     = "t2.medium"
}

variable "aws_ssh_key_name" {
  description = "The name of the SSH key pair to attach to the EC2 instances"
  type        = string
  default     = "Terraform_TBOT"
}

variable "TWS_USERID" {
  description = "The username for TWS"
  type        = string
  default     = "ChangeID"
}

variable "TWS_PASSWORD" {
  description = "The password for TWS"
  type        = string
  default     = "ChangePassword"
}

variable "NGROK_AUTH" {
  description = "Ngrok Auth Code"
  type        = string
  default     = "NGROK_AUTH"
}

variable "TBOT_IBKR_IPADDR" {
  description = "IP address for IBKR"
  type        = string
  default     = "ib-gateway"
}

# Variable for allowed IP addresses
variable "aws_ALLOWED_IPS" {
  description = "List of allowed IP addresses for security group ingress rules"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Default to allow all addresses
}

# AWS Provider configuration
provider "aws" {
  region = var.aws_region
}

# Create a security group to allow SSH, VNC, TradingBoat web interface, and Ngrok Web Agent connections
resource "aws_security_group" "tbot_terraform_security_group" {
  name        = "tbot-terraform-security-group"
  description = "Security group for Tbot on TradingBoat"

  # Add inbound rules to allow SSH, VNC, TradingBoat web interface, and Ngrok Web Agent connections
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH Access"
  }

  ingress {
    from_port   = 5900
    to_port     = 5901
    protocol    = "tcp"
    cidr_blocks = var.aws_ALLOWED_IPS
    description = "VNC Port"
  }

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = var.aws_ALLOWED_IPS
    description = "Redis"
  }

  # Add inbound rules to allow specified IP addresses on ports 80 and 443
  ingress {
    from_port   = 80  # HTTP Port
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["52.89.214.238/32", "34.212.75.30/32", "54.218.53.128/32", "52.32.178.7/32"]
    description = "TradingView Webhook Access"
  }

  ingress {
    from_port   = 443  # HTTPS Port
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["52.89.214.238/32", "34.212.75.30/32", "54.218.53.128/32", "52.32.178.7/32"]
    description = "TradingView Webhook Access"
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = var.aws_ALLOWED_IPS  # Use the aws_ALLOWED_IPS variable
    description = "TradingBoat web interface"
  }

  ingress {
    from_port   = 4040
    to_port     = 4040
    protocol    = "tcp"
    cidr_blocks = var.aws_ALLOWED_IPS  # Use the aws_ALLOWED_IPS variable
    description = "Ngrok Web Agent"
  }

  # Add an outbound rule to allow all outgoing traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # All protocols
    cidr_blocks = ["0.0.0.0/0"]  # Use the aws_ALLOWED_IPS variable
    description = "Allow all outbound traffic"
  }
}

# Elastic IP allocation
resource "aws_eip" "tbot_eip" {
  # No attributes are necessary
}

# Data Source for User Data Template
data "template_file" "user_data" {
  template = file("${path.module}/user_data.tpl")
  vars = {
    TWS_USERID         = var.TWS_USERID
    TWS_PASSWORD       = var.TWS_PASSWORD
    TBOT_IBKR_IPADDR   = var.TBOT_IBKR_IPADDR
    NGROK_AUTH         = var.NGROK_AUTH
    TBOT_DOCKER_BRANCH = var.TBOT_DOCKER_BRANCH
    # Add more
  }
}

# Launch an EC2 instance
resource "aws_instance" "tbot_instance" {
  ami             = var.ami_id
  aws_instance_type   = var.aws_instance_type 
  aws_ssh_key_name        = var.aws_ssh_key_name
  security_groups = [aws_security_group.tbot_terraform_security_group.name]

  # User data script to configure the instance (e.g., install Docker, create user, setup variables)
  user_data = data.template_file.user_data.rendered

  root_block_device {
    volume_size = 10  # Set the root volume size to 10GB
  }

  # Add tags for easy identification
  tags = {
    Name = "TbotInstance"
  }
}

# Associate Elastic IP with the EC2 instance
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.tbot_instance.id
  allocation_id = aws_eip.tbot_eip.id
}

# Output the public IP of the instance
output "instance_public_ip" {
  value = aws_eip.tbot_eip.public_ip
}
