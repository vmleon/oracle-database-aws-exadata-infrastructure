# ------------------------------------------------------------------------------
# ODB Network Outputs
# ------------------------------------------------------------------------------

output "odb_network_id" {
  description = "ID of the ODB Network."
  value       = aws_odb_network.this.id
}

output "odb_network_arn" {
  description = "ARN of the ODB Network."
  value       = aws_odb_network.this.arn
}

# ------------------------------------------------------------------------------
# Exadata Infrastructure Outputs
# ------------------------------------------------------------------------------

output "exadata_infrastructure_id" {
  description = "ID of the Exadata Infrastructure."
  value       = aws_odb_cloud_exadata_infrastructure.this.id
}

output "exadata_infrastructure_arn" {
  description = "ARN of the Exadata Infrastructure."
  value       = aws_odb_cloud_exadata_infrastructure.this.arn
}

output "exadata_infrastructure_ocid" {
  description = "Oracle Cloud Infrastructure OCID of the Exadata Infrastructure."
  value       = aws_odb_cloud_exadata_infrastructure.this.ocid
}

output "db_server_ids" {
  description = "List of database server IDs. Use these when creating a VM Cluster."
  value       = data.aws_odb_db_servers.this.db_servers[*].id
}

output "db_server_version" {
  description = "Software version running on database servers."
  value       = aws_odb_cloud_exadata_infrastructure.this.db_server_version
}

output "storage_server_version" {
  description = "Software version running on storage servers."
  value       = aws_odb_cloud_exadata_infrastructure.this.storage_server_version
}

# ------------------------------------------------------------------------------
# Exadata Infrastructure Capacity Outputs
# ------------------------------------------------------------------------------

output "cpu_count" {
  description = "Total CPU cores allocated to the Exadata Infrastructure."
  value       = aws_odb_cloud_exadata_infrastructure.this.cpu_count
}

output "max_cpu_count" {
  description = "Maximum CPU cores available on the Exadata Infrastructure."
  value       = aws_odb_cloud_exadata_infrastructure.this.max_cpu_count
}

output "memory_size_in_gbs" {
  description = "Total memory allocated in GB."
  value       = aws_odb_cloud_exadata_infrastructure.this.memory_size_in_gbs
}

output "data_storage_size_in_tbs" {
  description = "Total data storage capacity in TB."
  value       = aws_odb_cloud_exadata_infrastructure.this.data_storage_size_in_tbs
}

# ------------------------------------------------------------------------------
# OCI Metadata Outputs
# Extracted from the OCI console URL for cross-cloud reference
# ------------------------------------------------------------------------------

output "oci_url" {
  description = "Direct link to the Exadata Infrastructure in the OCI Console."
  value       = aws_odb_cloud_exadata_infrastructure.this.oci_url
}

output "oci_region" {
  description = "OCI region where the Exadata Infrastructure is registered."
  value       = try(regex("(?i:region=)([^?&/]+)", aws_odb_cloud_exadata_infrastructure.this.oci_url)[0], null)
}

output "oci_compartment_ocid" {
  description = "OCI compartment OCID containing the Exadata Infrastructure."
  value       = try(regex("(?i:compartmentId=)([^?&/]+)", aws_odb_cloud_exadata_infrastructure.this.oci_url)[0], null)
}

output "oci_tenant" {
  description = "OCI tenant name."
  value       = try(regex("(?i:tenant=)([^?&/]+)", aws_odb_cloud_exadata_infrastructure.this.oci_url)[0], null)
}

# ------------------------------------------------------------------------------
# Availability Zone Outputs
# ------------------------------------------------------------------------------

output "availability_zone" {
  description = "Availability Zone where resources are deployed."
  value       = var.availability_zone
}

output "availability_zone_id" {
  description = "Availability Zone ID (consistent across AWS accounts)."
  value       = data.aws_availability_zone.selected.zone_id
}

# ------------------------------------------------------------------------------
# VPC Outputs (only when create_vpc = true)
# ------------------------------------------------------------------------------

output "vpc_id" {
  description = "ID of the created VPC. Null if create_vpc is false."
  value       = var.create_vpc ? aws_vpc.application[0].id : null
}

output "vpc_cidr_block" {
  description = "CIDR block of the created VPC. Null if create_vpc is false."
  value       = var.create_vpc ? aws_vpc.application[0].cidr_block : null
}

output "app_subnet_id" {
  description = "ID of the application subnet. Null if create_vpc is false."
  value       = var.create_vpc ? aws_subnet.app[0].id : null
}

# ------------------------------------------------------------------------------
# Peering Connection Outputs (only when create_peering = true)
# ------------------------------------------------------------------------------

output "peering_connection_id" {
  description = "ID of the ODB Network Peering Connection. Null if create_peering is false."
  value       = var.create_peering ? aws_odb_network_peering_connection.this[0].id : null
}

output "peering_connection_arn" {
  description = "ARN of the ODB Network Peering Connection. Null if create_peering is false."
  value       = var.create_peering ? aws_odb_network_peering_connection.this[0].arn : null
}
