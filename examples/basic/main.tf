# ------------------------------------------------------------------------------
# Basic Example
# Deploys Oracle Database@AWS Exadata Infrastructure with a sample VPC for testing
# ------------------------------------------------------------------------------

# IMPORTANT: Configure the AWS provider in your root module, not in this module.
# The module inherits the provider configuration from the calling module.
provider "aws" {
  region = "us-east-1"
}

module "exadata" {
  source = "../../"

  # Required variables
  name_prefix       = "myapp"
  aws_region        = "us-east-1"
  availability_zone = "us-east-1a"
  contact_email     = "team@example.com"

  # Create a sample VPC for testing connectivity
  create_vpc     = true
  create_peering = true

  # Optional: customize the infrastructure
  # exadata_shape        = "Exadata.X11M"
  # compute_count        = 2
  # storage_count        = 3
  # database_server_type = "X11M"
  # storage_server_type  = "X11M-HC"
}

# Outputs for next steps (VM Cluster creation)
output "db_server_ids" {
  description = "Use these IDs when creating a VM Cluster"
  value       = module.exadata.db_server_ids
}

output "exadata_infrastructure_id" {
  description = "Exadata Infrastructure ID"
  value       = module.exadata.exadata_infrastructure_id
}

output "oci_url" {
  description = "Link to OCI Console"
  value       = module.exadata.oci_url
}
