# ------------------------------------------------------------------------------
# Oracle Database@AWS - Exadata Infrastructure Module
#
# This module provisions:
# - ODB Network (required) - Oracle's managed network for database connectivity
# - Exadata Infrastructure (required) - Cloud Exadata hardware
# - Sample VPC (optional) - For testing/demo connectivity
# - VPC Peering (optional) - Connect ODB network to your application VPCs
#
# IMPORTANT: Do NOT configure the AWS provider in this module. Configure it in
# your root module and this module will inherit that configuration.
#
# For production deployments:
# - Set create_vpc = false and use existing_vpc_id for peering
# - Coordinate CIDR ranges with your network team
# - Use S3 backend with DynamoDB locking for state management
# ------------------------------------------------------------------------------

locals {
  resource_name = var.name_suffix != "" ? "${var.name_prefix}-${var.name_suffix}" : var.name_prefix

  # Determine which VPC to peer with (created or existing)
  peer_vpc_id = var.create_vpc ? aws_vpc.application[0].id : var.existing_vpc_id

  default_tags = merge(var.tags, {
    managed_by = "terraform"
    module     = "oracle-database-aws-exadata-infrastructure"
  })

  # Extract generation from exadata_shape (e.g., "Exadata.X11M" -> "X11M")
  shape_generation = regex("Exadata\\.(X[0-9]+M)", var.exadata_shape)[0]

  # Validate that server types match the shape generation
  db_server_matches      = startswith(var.database_server_type, local.shape_generation)
  storage_server_matches = startswith(var.storage_server_type, local.shape_generation)

  # CIDR overlap validation
  # Extract network octets for comparison
  client_octets = split(".", cidrhost(var.client_subnet_cidr, 0))
  backup_octets = split(".", cidrhost(var.backup_subnet_cidr, 0))
  vpc_octets    = split(".", cidrhost(var.vpc_cidr, 0))
  vpc_prefix    = tonumber(split("/", var.vpc_cidr)[1])

  # Client and backup subnets must have different network addresses
  client_backup_overlap = cidrhost(var.client_subnet_cidr, 0) == cidrhost(var.backup_subnet_cidr, 0)

  # For VPC overlap, check if subnet falls within VPC range based on VPC prefix length
  # /16 VPC: first 2 octets must differ from subnets
  # /8 VPC: first octet must differ from subnets
  vpc_client_overlap = var.create_vpc ? (
    local.vpc_prefix <= 16 ? (
      local.vpc_octets[0] == local.client_octets[0] && local.vpc_octets[1] == local.client_octets[1]
    ) : (
      local.vpc_prefix <= 8 ? local.vpc_octets[0] == local.client_octets[0] : false
    )
  ) : false

  vpc_backup_overlap = var.create_vpc ? (
    local.vpc_prefix <= 16 ? (
      local.vpc_octets[0] == local.backup_octets[0] && local.vpc_octets[1] == local.backup_octets[1]
    ) : (
      local.vpc_prefix <= 8 ? local.vpc_octets[0] == local.backup_octets[0] : false
    )
  ) : false
}

# ------------------------------------------------------------------------------
# Data Sources
# ------------------------------------------------------------------------------

data "aws_availability_zone" "selected" {
  name = var.availability_zone
}

# ------------------------------------------------------------------------------
# ODB Network
# The Oracle-managed network that provides connectivity for Exadata infrastructure
# ------------------------------------------------------------------------------

resource "aws_odb_network" "this" {
  display_name         = "${local.resource_name}-odb-network"
  availability_zone    = var.availability_zone
  availability_zone_id = data.aws_availability_zone.selected.zone_id
  client_subnet_cidr   = var.client_subnet_cidr
  backup_subnet_cidr   = var.backup_subnet_cidr
  s3_access            = var.s3_access
  zero_etl_access      = var.zero_etl_access
  region               = var.aws_region

  tags = merge(local.default_tags, {
    Name = "${local.resource_name}-odb-network"
  })

  lifecycle {
    precondition {
      condition     = !local.client_backup_overlap
      error_message = "client_subnet_cidr (${var.client_subnet_cidr}) and backup_subnet_cidr (${var.backup_subnet_cidr}) must not overlap."
    }
    precondition {
      condition     = !local.vpc_client_overlap
      error_message = "vpc_cidr (${var.vpc_cidr}) and client_subnet_cidr (${var.client_subnet_cidr}) must not overlap."
    }
    precondition {
      condition     = !local.vpc_backup_overlap
      error_message = "vpc_cidr (${var.vpc_cidr}) and backup_subnet_cidr (${var.backup_subnet_cidr}) must not overlap."
    }
  }
}

# ------------------------------------------------------------------------------
# Exadata Infrastructure
# Cloud Exadata hardware provisioning - this is the core resource
# ------------------------------------------------------------------------------

resource "aws_odb_cloud_exadata_infrastructure" "this" {
  display_name         = "${local.resource_name}-exadata"
  shape                = var.exadata_shape
  compute_count        = var.compute_count
  storage_count        = var.storage_count
  availability_zone    = var.availability_zone
  availability_zone_id = data.aws_availability_zone.selected.zone_id
  database_server_type = var.database_server_type
  storage_server_type  = var.storage_server_type
  region               = var.aws_region

  customer_contacts_to_send_to_oci = [
    { email = var.contact_email }
  ]

  maintenance_window {
    preference                       = var.maintenance_window.preference
    patching_mode                    = var.maintenance_window.patching_mode
    is_custom_action_timeout_enabled = var.maintenance_window.is_custom_action_timeout_enabled
    custom_action_timeout_in_mins    = var.maintenance_window.custom_action_timeout_in_mins
  }

  tags = merge(local.default_tags, {
    Name = "${local.resource_name}-exadata"
  })

  timeouts {
    create = var.timeouts.create
    update = var.timeouts.update
    delete = var.timeouts.delete
  }

  lifecycle {
    precondition {
      condition     = local.db_server_matches
      error_message = "database_server_type '${var.database_server_type}' must match exadata_shape generation '${local.shape_generation}'."
    }
    precondition {
      condition     = local.storage_server_matches
      error_message = "storage_server_type '${var.storage_server_type}' must match exadata_shape generation '${local.shape_generation}'."
    }
  }
}

# Get database server IDs from Exadata Infrastructure (needed for VM Cluster creation)
data "aws_odb_db_servers" "this" {
  cloud_exadata_infrastructure_id = aws_odb_cloud_exadata_infrastructure.this.id
}

# ------------------------------------------------------------------------------
# Sample VPC for Testing/Demo (Optional)
# Set create_vpc = true to create this infrastructure
#
# NOTE: This creates a private VPC without internet access. The subnet uses
# the VPC's default route table (local routes only). You will need to:
# - Create security groups to allow traffic between your applications and
#   the Oracle database via the peering connection
# - Add a NAT Gateway or VPC endpoints if your applications need internet access
# ------------------------------------------------------------------------------

resource "aws_vpc" "application" {
  count = var.create_vpc ? 1 : 0

  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.default_tags, {
    Name = "${local.resource_name}-vpc"
  })
}

resource "aws_subnet" "app" {
  count = var.create_vpc ? 1 : 0

  vpc_id                  = aws_vpc.application[0].id
  cidr_block              = var.app_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false

  tags = merge(local.default_tags, {
    Name = "${local.resource_name}-app-subnet"
  })
}

# ------------------------------------------------------------------------------
# VPC Peering Connection (Optional)
# Connects ODB network to either the created VPC or an existing VPC
# ------------------------------------------------------------------------------

resource "aws_odb_network_peering_connection" "this" {
  count = var.create_peering ? 1 : 0

  depends_on = [aws_odb_network.this]

  display_name    = "${local.resource_name}-peering"
  odb_network_id  = aws_odb_network.this.id
  peer_network_id = local.peer_vpc_id
  region          = var.aws_region

  tags = merge(local.default_tags, {
    Name = "${local.resource_name}-peering"
  })

  lifecycle {
    precondition {
      condition     = local.peer_vpc_id != null
      error_message = "When create_peering is true, either create_vpc must be true or existing_vpc_id must be provided."
    }
  }
}
