# terraform-aws-rds-postgres

[![Terraform Version](https://img.shields.io/badge/Terraform%20Version->=0.13.0,_<0.14.0-blue.svg)](https://releases.hashicorp.com/terraform/)
[![Release](https://img.shields.io/github/release/traveloka/terraform-aws-rds-postgres.svg)](https://github.com/traveloka/terraform-aws-rds-postgres/releases)
[![Last Commit](https://img.shields.io/github/last-commit/traveloka/terraform-aws-rds-postgres.svg)](https://github.com/traveloka/terraform-aws-rds-postgres/commits/master)
[![Issues](https://img.shields.io/github/issues/traveloka/terraform-aws-rds-postgres.svg)](https://github.com/traveloka/terraform-aws-rds-postgres/issues)
[![Pull Requests](https://img.shields.io/github/issues-pr/traveloka/terraform-aws-rds-postgres.svg)](https://github.com/traveloka/terraform-aws-rds-postgres/pulls)
[![License](https://img.shields.io/github/license/traveloka/terraform-aws-rds-postgres.svg)](https://github.com/traveloka/terraform-aws-rds-postgres/blob/master/LICENSE)
![Open Source Love](https://badges.frapsoft.com/os/v1/open-source.png?v=103)

## Description

Terraform module which creates an AWS RDS Postgres.


## Prerequisites

Requirements
------------

- An existing VPC
- An existing DB subnet group
- An existing Postgres parameter group
- An existing RDS Enhanced Monitoring role
- Existing DB security groups

Password for Master DB
----------------------

- The module will generate a random 16 characters long password.
- The module will output this password.
- Make sure that you change the password after the provisioning is successfully completed.

Read Replica
------------

If `replicate_source_db` parameter is defined, it indicates that the instance is meant to be a read replica.

These parameters will be inherited from the master's in the first creation stage:
1. allocated_storage
2. maintenance_window
3. parameter_group_name 
4. vpc_security_group_ids

To apply different values for the parameters above, you have to re-apply the configuration after the first creation is finished.

Some default values are changed for read replica instance:
- `backup_retention_period = 0`
  Postgres read replica does not support automated backup.

- `skip_final_snapshot = true`
  When deleting a read replica, a final snapshot cannot be created.

- `copy_tags_to_snapshot = false`
  When deleting a read replica, a final snapshot is not created.

### How to promote a read replica?

These steps need to be done in sequence:
1. Remove parameter `replicate_source_db`
   This is to indicate that the instance is meant to be a master instance.

2. Add parameter `backup_retention_period = 0`
   We need to explicitly disable automated backup for now, otherwise Terraform will complain that a read replica does not support automated backup.

3. Apply the configuration and wait for db instance to be successfully promoted to master

4. Remove parameter `availability_zone`
   We are using `multi_az` parameter for master instance.

5. Modify parameter `multi_az`
   This is to enable multi AZ. Either set it explicitly or leave as default.

6. Modify parameter `backup_retention_period`
   This is to enable automated backup. Either set it explicitly or leave as default.

7. Add parameter `backup_window`
   Either set it explicitly or leave as default.

8. Modify other parameters as you would to a master instance

9. Apply the configuration again


## Dependencies

This Terraform module have no dependencies to another modules


## Getting Started

```hcl
module "postgres" {
  source  = "github.com/traveloka/terraform-aws-rds-postgres?ref=v1.3.0"

  product_domain = "txt"
  service_name   = "txtinv"
  environment    = "production"
  description    = "Postgres to store Transport Extranet (txt) inventory data"

  instance_class = "db.t2.small"
  engine_version = "9.6.6"

  allocated_storage = 100

  multi_az = true

  # Change to valid security group id
  vpc_security_group_ids = [
    "sg-50036436"
  ]

  # Change to valid db subnet group name
  db_subnet_group_name = "tvlk-dev-rds-subnet-group"

  # Change to valid parameter group name
  parameter_group_name = "default.postgres9.6"

  maintenance_window      = "Mon:00:00-Mon:03:00"
  backup_retention_period = 0

  skip_final_snapshot = true

  # Change to valid monitoring role arn
  monitoring_role_arn = "arn:aws:iam::517530806209:role/rds-monitoring-role"

  # Change to valid route 53 zone id
  route53_zone_id = "Z32OEBZ2VZHSJZ"
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_db_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [random_id.db_identifier](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_id.password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_tags"></a> [additional\_tags](#input\_additional\_tags) | The additional aws\_db\_instance tags that will be merged over the default tags | `map(string)` | `{}` | no |
| <a name="input_allocated_storage"></a> [allocated\_storage](#input\_allocated\_storage) | The allocated storage in gigabytes. For read replica, set the same value as master's | `string` | n/a | yes |
| <a name="input_allow_major_version_upgrade"></a> [allow\_major\_version\_upgrade](#input\_allow\_major\_version\_upgrade) | Indicates that major version upgrades are allowed | `string` | `"false"` | no |
| <a name="input_apply_immediately"></a> [apply\_immediately](#input\_apply\_immediately) | Specifies whether any database modifications are applied immediately, or during the next maintenance window | `string` | `"false"` | no |
| <a name="input_auto_minor_version_upgrade"></a> [auto\_minor\_version\_upgrade](#input\_auto\_minor\_version\_upgrade) | Indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window | `string` | `"false"` | no |
| <a name="input_availability_zone"></a> [availability\_zone](#input\_availability\_zone) | The AZ for the RDS instance. It is recommended to only use this when creating a read replica instance | `string` | `""` | no |
| <a name="input_backup_retention_period"></a> [backup\_retention\_period](#input\_backup\_retention\_period) | The days to retain backups for | `string` | `7` | no |
| <a name="input_backup_window"></a> [backup\_window](#input\_backup\_window) | The daily time range (in UTC) during which automated backups are created if they are enabled. Before and not overlap with maintenance\_window | `string` | `""` | no |
| <a name="input_bastion_security_group_id"></a> [bastion\_security\_group\_id](#input\_bastion\_security\_group\_id) | bastion security groups to associate | `string` | n/a | yes |
| <a name="input_ca_cert_identifier"></a> [ca\_cert\_identifier](#input\_ca\_cert\_identifier) | Specifies the identifier of the CA certificate for the DB instance | `string` | `"rds-ca-2019"` | no |
| <a name="input_copy_tags_to_snapshot"></a> [copy\_tags\_to\_snapshot](#input\_copy\_tags\_to\_snapshot) | On delete, copy all Instance tags to the final snapshot (if final\_snapshot\_identifier is specified) | `string` | `"true"` | no |
| <a name="input_db_subnet_group_name"></a> [db\_subnet\_group\_name](#input\_db\_subnet\_group\_name) | Name of DB subnet group | `string` | `""` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | If the DB instance should have deletion protection enabled. The database can't be deleted when this value is set to true. The default is false | `string` | `false` | no |
| <a name="input_description"></a> [description](#input\_description) | The description of this RDS instance | `string` | n/a | yes |
| <a name="input_enabled_cloudwatch_logs_exports"></a> [enabled\_cloudwatch\_logs\_exports](#input\_enabled\_cloudwatch\_logs\_exports) | List of log types to enable for exporting to CloudWatch logs | `list(string)` | `[]` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | The postgres engine version | `string` | `""` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment this RDS belongs to | `string` | n/a | yes |
| <a name="input_instance_class"></a> [instance\_class](#input\_instance\_class) | The instance type of the RDS instance | `string` | n/a | yes |
| <a name="input_iops"></a> [iops](#input\_iops) | The amount of provisioned IOPS. Setting this implies a storage\_type of io1 | `string` | `"0"` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | Specifies a custom KMS key to be used to encrypt | `string` | `""` | no |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | The window to perform maintenance in. Syntax: 'ddd:hh24:mi-ddd:hh24:mi' | `string` | n/a | yes |
| <a name="input_max_allocated_storage"></a> [max\_allocated\_storage](#input\_max\_allocated\_storage) | The upper limit to which Amazon RDS can automatically scale the storage of the DB instance. Set this value to be greater than or equal to allocated\_storage or 0 to disable Storage Autoscaling. | `string` | `"0"` | no |
| <a name="input_monitoring_interval"></a> [monitoring\_interval](#input\_monitoring\_interval) | The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance | `string` | `"60"` | no |
| <a name="input_monitoring_role_arn"></a> [monitoring\_role\_arn](#input\_monitoring\_role\_arn) | The ARN for the IAM role that permits RDS to send enhanced monitoring metrics to CloudWatch Logs | `string` | n/a | yes |
| <a name="input_multi_az"></a> [multi\_az](#input\_multi\_az) | Specifies if the RDS instance is multi-AZ | `string` | `"true"` | no |
| <a name="input_parameter_group_name"></a> [parameter\_group\_name](#input\_parameter\_group\_name) | Name of the DB parameter group to associate | `string` | n/a | yes |
| <a name="input_performance_insights_enabled"></a> [performance\_insights\_enabled](#input\_performance\_insights\_enabled) | The values which defines if the performance insights for this db will be enabled or not | `string` | `"false"` | no |
| <a name="input_pitr_restore_time"></a> [pitr\_restore\_time](#input\_pitr\_restore\_time) | The date and time to restore from | `string` | `null` | no |
| <a name="input_pitr_source_db_instance_automated_backups_arn"></a> [pitr\_source\_db\_instance\_automated\_backups\_arn](#input\_pitr\_source\_db\_instance\_automated\_backups\_arn) | The ARN of the source database instance automated backups to restore from | `string` | `null` | no |
| <a name="input_pitr_source_db_instance_identifier"></a> [pitr\_source\_db\_instance\_identifier](#input\_pitr\_source\_db\_instance\_identifier) | The source database instance identifier to restore from | `string` | `null` | no |
| <a name="input_pitr_source_dbi_resource_id"></a> [pitr\_source\_dbi\_resource\_id](#input\_pitr\_source\_dbi\_resource\_id) | The resource ID of the source database instance automated backups to restore from | `string` | `null` | no |
| <a name="input_pitr_use_latest_restorable_time"></a> [pitr\_use\_latest\_restorable\_time](#input\_pitr\_use\_latest\_restorable\_time) | Specifies whether or not to restore the DB instance to the latest restorable backup time | `string` | `null` | no |
| <a name="input_port"></a> [port](#input\_port) | The port on which the DB accepts connections | `string` | `"5432"` | no |
| <a name="input_product_domain"></a> [product\_domain](#input\_product\_domain) | The name of the product domain this RDS belongs to | `string` | n/a | yes |
| <a name="input_replicate_source_db"></a> [replicate\_source\_db](#input\_replicate\_source\_db) | The source db of read replica instance | `string` | `null` | no |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | The name of the service this RDS belongs to, this will be part of the database identifier | `string` | n/a | yes |
| <a name="input_skip_final_snapshot"></a> [skip\_final\_snapshot](#input\_skip\_final\_snapshot) | Determines whether a final DB snapshot is created before the DB instance is deleted | `string` | `"false"` | no |
| <a name="input_snapshot_identifier"></a> [snapshot\_identifier](#input\_snapshot\_identifier) | The snapshot ID used to restore the DB instance | `string` | `null` | no |
| <a name="input_storage_encrypted"></a> [storage\_encrypted](#input\_storage\_encrypted) | Specifies whether the DB instance is encrypted | `string` | `"true"` | no |
| <a name="input_storage_type"></a> [storage\_type](#input\_storage\_type) | One of standard (magnetic), gp2 (general purpose SSD), or io1 (provisioned IOPS SSD) | `string` | `"gp2"` | no |
| <a name="input_username"></a> [username](#input\_username) | Username for the master DB user | `string` | `"postgres"` | no |
| <a name="input_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | List of VPC security groups to associate | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_address"></a> [address](#output\_address) | The address of the RDS instance |
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN of the RDS instance |
| <a name="output_availability_zone"></a> [availability\_zone](#output\_availability\_zone) | The availability zone of the instance |
| <a name="output_endpoint"></a> [endpoint](#output\_endpoint) | The connection endpoint |
| <a name="output_hosted_zone_id"></a> [hosted\_zone\_id](#output\_hosted\_zone\_id) | The canonical hosted zone ID of the DB instance (to be used in a Route 53 Alias record) |
| <a name="output_id"></a> [id](#output\_id) | The RDS instance ID |
| <a name="output_password"></a> [password](#output\_password) | The password for the DB |
| <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id) | The RDS Resource ID of this instance |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Contributing

This module accepting or open for any contributions from anyone, please see the [CONTRIBUTING.md](https://github.com/traveloka/terraform-aws-private-route53-zone/blob/master/CONTRIBUTING.md) for more detail about how to contribute to this module.

## License

This module is under Apache License 2.0 - see the [LICENSE](https://github.com/traveloka/terraform-aws-private-route53-zone/blob/master/LICENSE) file for details.
