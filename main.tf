locals {
  max_byte_length = 8

  db_identifier_max_length = 63
  db_identifier_prefix     = "${var.service_name}-postgres-"

  db_identifier_suffix_max_byte_length = floor((local.db_identifier_max_length - length(local.db_identifier_prefix)) / 2)
  db_identifier_suffix_byte_length = min(
    local.max_byte_length,
    local.db_identifier_suffix_max_byte_length,
  )

  final_snapshot_identifier = "${random_id.db_identifier.hex}-final-snapshot"

  # Change default values for read replica instance
  is_read_replica         = var.replicate_source_db == "" ? false : true
  username                = local.is_read_replica ? "" : var.username
  password                = local.is_read_replica ? "" : var.snapshot_identifier == "" ? random_id.password.hex : ""
  multi_az                = var.multi_az
  backup_retention_period = local.is_read_replica ? 0 : var.backup_retention_period
  skip_final_snapshot     = local.is_read_replica ? true : var.skip_final_snapshot
  copy_tags_to_snapshot   = local.is_read_replica ? false : var.copy_tags_to_snapshot

  default_tags = {
    Name          = random_id.db_identifier.hex
    Service       = var.service_name
    ProductDomain = var.product_domain
    Environment   = var.environment
    Description   = var.description
    ManagedBy     = "terraform"
    OrgAWSBackup  = var.aws_backup_frequency
  }
}

resource "random_id" "db_identifier" {
  prefix      = local.db_identifier_prefix
  byte_length = local.db_identifier_suffix_byte_length
}

# Generate a random 16 characters password
resource "random_id" "password" {
  byte_length = 8
}

resource "aws_db_instance" "this" {
  # Ignore changes on password as it is expected to be changed outside of Terraform
  # Ignore changes on snapshot_identifier as it is expected to use this one time only when restoring from snapshot
  lifecycle {
    ignore_changes = [
      password,
      snapshot_identifier,
    ]
  }

  identifier = random_id.db_identifier.hex

  # Indicates that this instance is a read replica
  replicate_source_db = var.replicate_source_db

  engine             = "postgres"
  engine_version     = var.engine_version
  instance_class     = var.instance_class
  username           = var.username
  password           = local.password
  port               = var.port
  ca_cert_identifier = var.ca_cert_identifier

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  iops                  = var.iops
  storage_encrypted     = var.storage_encrypted
  kms_key_id            = var.kms_key_id

  vpc_security_group_ids = flatten([
    var.vpc_security_group_ids,
    var.bastion_security_group_id
  ])

  multi_az            = local.multi_az
  publicly_accessible = false

  db_subnet_group_name = var.db_subnet_group_name
  parameter_group_name = var.parameter_group_name

  allow_major_version_upgrade = var.allow_major_version_upgrade
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  apply_immediately           = var.apply_immediately
  maintenance_window          = var.maintenance_window
  deletion_protection         = var.deletion_protection

  backup_retention_period = local.backup_retention_period
  backup_window           = var.backup_window

  skip_final_snapshot       = local.skip_final_snapshot
  final_snapshot_identifier = local.final_snapshot_identifier
  copy_tags_to_snapshot     = local.copy_tags_to_snapshot
  snapshot_identifier       = var.snapshot_identifier

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_role_arn

  performance_insights_enabled = var.performance_insights_enabled

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  tags = merge(var.additional_tags, local.default_tags)
}

