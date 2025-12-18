# ------------------------------------------------------------------------------
# Production Example with Existing VPC
# Deploys Oracle Database@AWS Exadata Infrastructure peered with an existing VPC
# ------------------------------------------------------------------------------

# IMPORTANT: Configure the AWS provider in your root module, not in this module.
# The module inherits the provider configuration from the calling module.
provider "aws" {
  region = "us-east-1"
}

# Reference your existing VPC
data "aws_vpc" "existing" {
  id = "vpc-0123456789abcdef0" # Replace with your VPC ID
}

module "exadata" {
  source = "../../"

  # Required variables
  name_prefix       = "prod"
  aws_region        = "us-east-1"
  availability_zone = "us-east-1a"
  contact_email     = "dba-team@example.com"

  # IMPORTANT: Coordinate these CIDRs with your network team to avoid conflicts
  # These must not overlap with your existing VPC CIDR or any peered networks
  client_subnet_cidr = "10.33.1.0/24"
  backup_subnet_cidr = "10.33.0.0/24"

  # Peer with existing VPC instead of creating a new one
  create_vpc      = false
  existing_vpc_id = data.aws_vpc.existing.id
  create_peering  = true

  # Production configuration
  exadata_shape        = "Exadata.X11M"
  compute_count        = 2
  storage_count        = 3
  database_server_type = "X11M"
  storage_server_type  = "X11M-HC"

  # Enable S3 access for data import/export
  s3_access = "ENABLED"

  # Tags for cost tracking
  tags = {
    environment = "production"
    owner       = "dba-team"
    cost-center = "database-infrastructure"
  }
}

# After deployment, you need to:
# 1. Update route tables in your existing VPC to route traffic to the ODB network
# 2. Create security groups to allow database traffic (port 1521 for Oracle)
# 3. Create a VM Cluster using the db_server_ids output
# 4. Create Oracle Databases on the VM Cluster

output "db_server_ids" {
  description = "Use these IDs when creating a VM Cluster"
  value       = module.exadata.db_server_ids
}

output "exadata_infrastructure_id" {
  description = "Exadata Infrastructure ID"
  value       = module.exadata.exadata_infrastructure_id
}

output "peering_connection_id" {
  description = "VPC Peering Connection ID - add routes for this in your existing VPC"
  value       = module.exadata.peering_connection_id
}

output "client_subnet_cidr" {
  description = "CIDR to route to via the peering connection for database connectivity"
  value       = "10.33.1.0/24"
}
