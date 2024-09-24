
resource "aws_security_group" "wireguard" {
  tags = {
    Environment = var.environment_name
    Name        = "${var.environment_name} wireguard"
    ManagedBy   = "Terraform"
  }

  name   = "${var.environment_name}-wireguard"
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = length(var.allowed_security_groups_ingress) > 0 ? [1] : []
    content {
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      security_groups = var.allowed_security_groups_ingress
      description     = "Everything inbound from my homies"
    }
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = [var.private_subnet_cidr]
    description = "SSH inbound internally only"
  }

  ingress {
    from_port   = var.port_number
    to_port     = var.port_number
    protocol    = "UDP"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Wireguard inbound from the world (UDP)"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Wireguard outbound to the world"
  }
}

resource "aws_route53_record" "wireguard" {
  zone_id = var.dns_zone_id
  name    = var.dns_name
  type    = "A"
  ttl     = "60"
  records = [
    aws_instance.wireguard.public_ip
  ]
}

resource "aws_route53_record" "wireguard_internal" {
  zone_id = var.dns_zone_id
  name    = "internal-${var.dns_name}"
  type    = "A"
  ttl     = "60"
  records = [
    aws_instance.wireguard.private_ip
  ]
}

data "aws_s3_bucket" "s3_bucket" {
  bucket = var.s3_bucket_name
}

resource "aws_instance" "wireguard" {
  tags = {
    Name        = "${var.environment_name}-wireguard"
    Environment = var.environment_name
    ManagedBy   = "Terraform"
  }

  ami                         = var.ami
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.wireguard.id]
  subnet_id                   = var.vpc_subnet_id
  associate_public_ip_address = true
  key_name                    = var.ssh_key_name
  iam_instance_profile        = var.instance_profile

  capacity_reservation_specification {
    capacity_reservation_preference = "open"
  }

  credit_specification {
    cpu_credits = "standard"
  }

  enclave_options {
    enabled = false
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "optional"
  }

  root_block_device {
    delete_on_termination = false
    encrypted             = false
    iops                  = 3000
    throughput            = 125
    volume_size           = 8
    volume_type           = "gp3"

    tags = {
      Name        = "${var.environment_name}-wireguard root_block"
      Environment = var.environment_name
      ManagedBy   = "Terraform"
    }
  }

  user_data = "${file("../userdata-bastion-wireguard.sh")}"
}
