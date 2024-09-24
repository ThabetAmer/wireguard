# Wireguard Server

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_instance.wireguard](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_route53_record.wireguard](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.wireguard_internal](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_security_group.wireguard](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_s3_bucket.s3_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_security_groups_ingress"></a> [allowed\_security\_groups\_ingress](#input\_allowed\_security\_groups\_ingress) | n/a | `list(string)` | n/a | yes |
| <a name="input_ami"></a> [ami](#input\_ami) | n/a | `string` | `"ami-031b673f443c2172c"` | no |
| <a name="input_dns_name"></a> [dns\_name](#input\_dns\_name) | n/a | `string` | n/a | yes |
| <a name="input_dns_zone_id"></a> [dns\_zone\_id](#input\_dns\_zone\_id) | n/a | `string` | n/a | yes |
| <a name="input_instance_profile"></a> [instance\_profile](#input\_instance\_profile) | n/a | `string` | n/a | yes |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | n/a | `string` | `"t2.small"` | no |
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | n/a | `string` | n/a | yes |
| <a name="input_port_number"></a> [port\_number](#input\_port\_number) | n/a | `number` | `51820` | no |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | n/a | `string` | n/a | yes |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | n/a | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | n/a | `string` | n/a | yes |
| <a name="input_vpc_subnet_id"></a> [vpc\_subnet\_id](#input\_vpc\_subnet\_id) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_wireguard_public_ip"></a> [wireguard\_public\_ip](#output\_wireguard\_public\_ip) | n/a |
| <a name="output_wireguard_security_group_id"></a> [wireguard\_security\_group\_id](#output\_wireguard\_security\_group\_id) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->