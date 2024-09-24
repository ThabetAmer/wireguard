
variable "environment_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_subnet_id" {
  type = string
}

variable "allowed_security_groups_ingress" {
  type = list(string)
}

variable "dns_zone_id" {
  type = string
}

variable "dns_name" {
  type = string
}

variable "ssh_key_name" {
  type = string
}

variable "s3_bucket_name" {
  type = string
}

variable "instance_profile" {
  type = string
}

variable "port_number" {
  type    = number
  default = 51820
}

variable "ami" {
  type    = string
  default = "ami-031b673f443c2172c"
}

variable "instance_type" {
  type    = string
  default = "t3a.small"
}

variable "private_subnet_cidr" {
  type    = string
  default = "10.1.0.0/16"
}
