
output "wireguard_security_group_id" {
  value = aws_security_group.wireguard.id
}

output "wireguard_public_ip" {
  value = aws_instance.wireguard.public_ip
}
