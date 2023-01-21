provider "aws" {
  region = "ap-southeast-1"
}

# Existing VPC with a DB Subnet Group
data "aws_vpc" "test_vpc" {
  filter {
    name   = "tag:ProductDomain"
    values = ["test"]
  }
}

# Existing IAM Policy for RDS Enhanced Monitoring
data "aws_iam_policy" "rds_enhanced_monitoring" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

module "rds_enhanced_monitoring" {
  source = "git@github.com:traveloka/terraform-aws-iam-role.git//modules/service?ref=v4.0.1"

  role_identifier  = "RDS Enhanced Monitoring"
  role_description = "Provides access to Cloudwatch for RDS Enhanced Monitoring"
  aws_service      = "monitoring.rds.amazonaws.com"
  product_domain   = "tsi"
  environment      = "testing"
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = module.rds_enhanced_monitoring.role_name
  policy_arn = data.aws_iam_policy.rds_enhanced_monitoring.arn
}


module "txtbook_postgres" {
  source = "../../"

  product_domain = "txt"
  service_name   = "txtbook"
  environment    = "production"
  description    = "Postgres to store Tesla Extranet booking data"

  instance_class    = "db.t4g.micro"
  engine_version    = "13.7"
  allocated_storage = 20

  # Change to valid security group id
  vpc_security_group_ids = [
    aws_security_group.dummy_sg.id
  ]

  bastion_security_group_id = aws_security_group.bastion_sg.id

  # Change to valid db subnet group name
  db_subnet_group_name = "tvlk-dev-rds-subnet-group"

  # Change to valid parameter group name
  parameter_group_name = "default.postgres13"

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "21:00-23:00"

  # Change to valid monitoring role arn
  monitoring_role_arn = module.rds_enhanced_monitoring.role_arn
  ca_cert_identifier  = "rds-ca-2019"

  pitr_source_db_instance_identifier = "txtbook-postgres-1a1ebb524f522bde"
  pitr_use_latest_restorable_time    = true

  # If you want to restore to specific time
  # pitr_restore_time = "2023-01-01T00:00:00Z"


}

resource "aws_security_group" "dummy_sg" {
  name        = "tsidum-postgres"
  description = "dummy security group for testing postgres modules"
  vpc_id      = data.aws_vpc.test_vpc.id

  tags = {
    Name          = "tsitest-postgres"
    Service       = "tsitest"
    ProductDomain = "tsi"
    Environment   = "testing"
    description   = "dummy security group for testing postgres modules"
  }
}

resource "aws_security_group" "bastion_sg" {
  name        = "tsitest-bastion"
  description = "dummy security group for testing postgres modules"
  vpc_id      = data.aws_vpc.test_vpc.id

  tags = {
    Name          = "tsidum-postgres"
    Service       = "tsitest"
    ProductDomain = "tsi"
    Environment   = "testing"
    description   = "dummy bastion security group for testing postgres modules"
  }
}
