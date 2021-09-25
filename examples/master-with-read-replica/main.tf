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
  arn = "arn:aws:iam::460124681500:policy/VincentAmazonRDSEnhancedMonitoringRole"
}

module "rds_enhanced_monitoring" {
  source = "git@github.com:traveloka/terraform-aws-iam-role.git//modules/service?ref=v3.0.0"

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


module "txtbook_postgres_1" {
  source = "../../"

  apply_immediately = true

  product_domain = "txt"
  service_name   = "txtbook"
  environment    = "production"
  description    = "Postgres to store Tesla Extranet booking data"

  instance_class    = "db.t2.small"
  engine_version    = "9.6.6"
  allocated_storage = 20

  # Change to valid security group id
  vpc_security_group_ids = [
    aws_security_group.dummy_sg.id
  ]
  bastion_security_group_id = aws_security_group.bastion_sg.id

  # Change to valid db subnet group nam
  db_subnet_group_name = "tvlk-dev-rds-subnet-group"

  # Change to valid parameter group name
  parameter_group_name = "default.postgres9.6"

  maintenance_window      = "Mon:00:00-Mon:03:00"
  backup_window           = "21:00-23:00"
  backup_retention_period = 1

  # Change to valid monitoring role arn
  monitoring_role_arn = module.rds_enhanced_monitoring.role_arn
}

module "txtbook_postgres_2" {
  source = "../../"

  apply_immediately = true

  product_domain = "txt"
  service_name   = "txtbook"
  environment    = "production"
  description    = "Read replica of txtbook postgres for analytic purpose"

  # Indicates that this is a read replica
  replicate_source_db = module.txtbook_postgres_1.id

  instance_class = "db.t2.small"

  # Make sure that this is always identical to the master's
  allocated_storage = 20

  # Set the read replica AZ to be the master's AZ
  availability_zone = module.txtbook_postgres_1.availability_zone

  # Change to valid security group id
  vpc_security_group_ids = [
    aws_security_group.dummy_sg.id
  ]
  bastion_security_group_id = aws_security_group.bastion_sg.id
  # Change to valid parameter group name
  parameter_group_name = "acs-shared-postgres"

  maintenance_window = "Mon:21:00-Mon:23:00"

  # Change to valid monitoring role arn
  monitoring_role_arn = module.rds_enhanced_monitoring.role_arn
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
