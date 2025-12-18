# ------------------------------------------------------------------------------
# REQUIRED VARIABLES
# These variables must be set when using this module.
# ------------------------------------------------------------------------------

variable "name_prefix" {
  description = "Prefix for all resource names. Use lowercase alphanumeric characters and hyphens only."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.name_prefix))
    error_message = "name_prefix must start with a lowercase letter and contain only lowercase alphanumeric characters and hyphens."
  }
}

variable "aws_region" {
  description = "AWS region for deployment. Must be a region where Oracle Database@AWS is available."
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "aws_region must be a valid AWS region format (e.g., us-east-1, eu-west-1)."
  }
}

variable "contact_email" {
  description = "Email address for Oracle Cloud Infrastructure notifications. Required by Oracle for infrastructure alerts and maintenance communications."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.contact_email))
    error_message = "contact_email must be a valid email address."
  }
}

# ------------------------------------------------------------------------------
# OPTIONAL VARIABLES - General
# ------------------------------------------------------------------------------

variable "name_suffix" {
  description = "Optional suffix for resource names. Useful for ensuring uniqueness across deployments."
  type        = string
  default     = ""
}

variable "availability_zone" {
  description = "AWS Availability Zone for deployment. Must be in the specified aws_region and support Oracle Database@AWS."
  type        = string
  default     = null

  validation {
    condition     = var.availability_zone == null || can(regex("^[a-z]{2}-[a-z]+-[0-9][a-z]$", var.availability_zone))
    error_message = "availability_zone must be a valid AZ format (e.g., us-east-1a, eu-west-1b)."
  }
}

variable "tags" {
  description = "Map of tags to apply to all resources. Recommended: include 'environment', 'owner', and 'cost-center' tags for production."
  type        = map(string)
  default     = {}
}

# ------------------------------------------------------------------------------
# OPTIONAL VARIABLES - ODB Network Configuration
# ------------------------------------------------------------------------------

variable "client_subnet_cidr" {
  description = "CIDR block for the ODB client subnet. Must be /24 or larger. This subnet handles database client connections."
  type        = string
  default     = "10.33.1.0/24"

  validation {
    condition     = can(cidrhost(var.client_subnet_cidr, 0)) && tonumber(split("/", var.client_subnet_cidr)[1]) <= 24
    error_message = "client_subnet_cidr must be a valid CIDR block with prefix /24 or larger (smaller number)."
  }
}

variable "backup_subnet_cidr" {
  description = "CIDR block for the ODB backup subnet. Must be /24 or larger. This subnet handles database backup traffic to Oracle Cloud."
  type        = string
  default     = "10.33.0.0/24"

  validation {
    condition     = can(cidrhost(var.backup_subnet_cidr, 0)) && tonumber(split("/", var.backup_subnet_cidr)[1]) <= 24
    error_message = "backup_subnet_cidr must be a valid CIDR block with prefix /24 or larger (smaller number)."
  }
}

variable "s3_access" {
  description = "Enable S3 access from ODB network for data import/export operations."
  type        = string
  default     = "DISABLED"

  validation {
    condition     = contains(["ENABLED", "DISABLED"], var.s3_access)
    error_message = "s3_access must be either 'ENABLED' or 'DISABLED'."
  }
}

variable "zero_etl_access" {
  description = "Enable Zero-ETL access for real-time data integration with AWS analytics services."
  type        = string
  default     = "DISABLED"

  validation {
    condition     = contains(["ENABLED", "DISABLED"], var.zero_etl_access)
    error_message = "zero_etl_access must be either 'ENABLED' or 'DISABLED'."
  }
}

# ------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Exadata Infrastructure Configuration
# ------------------------------------------------------------------------------

variable "exadata_shape" {
  description = "Exadata infrastructure shape. Determines the generation and capabilities of the hardware."
  type        = string
  default     = "Exadata.X11M"

  validation {
    condition     = contains(["Exadata.X11M", "Exadata.X9M", "Exadata.X8M"], var.exadata_shape)
    error_message = "exadata_shape must be one of: Exadata.X11M, Exadata.X9M, Exadata.X8M."
  }
}

variable "compute_count" {
  description = "Number of database servers (compute nodes). Minimum 2 for high availability. Scale based on CPU and memory requirements."
  type        = number
  default     = 2

  validation {
    condition     = var.compute_count >= 2 && var.compute_count <= 32
    error_message = "compute_count must be between 2 and 32."
  }
}

variable "storage_count" {
  description = "Number of storage servers. Minimum 3 for data redundancy. Scale based on storage capacity and IOPS requirements."
  type        = number
  default     = 3

  validation {
    condition     = var.storage_count >= 3 && var.storage_count <= 64
    error_message = "storage_count must be between 3 and 64."
  }
}

variable "database_server_type" {
  description = "Database server model. Must align with exadata_shape: X11M for Exadata.X11M, X9M for Exadata.X9M, X8M for Exadata.X8M."
  type        = string
  default     = "X11M"

  validation {
    condition     = contains(["X11M", "X9M", "X8M"], var.database_server_type)
    error_message = "database_server_type must be one of: X11M, X9M, X8M."
  }
}

variable "storage_server_type" {
  description = "Storage server model. HC variants provide higher capacity. Must align with exadata_shape generation."
  type        = string
  default     = "X11M-HC"

  validation {
    condition     = contains(["X11M-HC", "X11M", "X9M-HC", "X9M", "X8M-HC", "X8M"], var.storage_server_type)
    error_message = "storage_server_type must be one of: X11M-HC, X11M, X9M-HC, X9M, X8M-HC, X8M."
  }
}

variable "maintenance_window" {
  description = "Maintenance window configuration for patching and updates."
  type = object({
    preference                       = optional(string, "NO_PREFERENCE")
    patching_mode                    = optional(string, "ROLLING")
    is_custom_action_timeout_enabled = optional(bool, false)
    custom_action_timeout_in_mins    = optional(number, 15)
  })
  default = {}

  validation {
    condition     = contains(["NO_PREFERENCE", "CUSTOM_PREFERENCE"], var.maintenance_window.preference)
    error_message = "maintenance_window.preference must be 'NO_PREFERENCE' or 'CUSTOM_PREFERENCE'."
  }

  validation {
    condition     = contains(["ROLLING", "NONROLLING"], var.maintenance_window.patching_mode)
    error_message = "maintenance_window.patching_mode must be 'ROLLING' or 'NONROLLING'."
  }
}

# ------------------------------------------------------------------------------
# OPTIONAL VARIABLES - VPC Configuration (for demo/testing)
# ------------------------------------------------------------------------------

variable "create_vpc" {
  description = "Create a sample VPC for connectivity testing. Set to false in production and use existing_vpc_id instead."
  type        = bool
  default     = false
}

variable "vpc_cidr" {
  description = "CIDR block for the sample VPC. Only used when create_vpc is true."
  type        = string
  default     = "10.34.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid CIDR block."
  }
}

variable "app_subnet_cidr" {
  description = "CIDR block for the application subnet in the sample VPC. Only used when create_vpc is true."
  type        = string
  default     = "10.34.1.0/24"

  validation {
    condition     = can(cidrhost(var.app_subnet_cidr, 0))
    error_message = "app_subnet_cidr must be a valid CIDR block."
  }
}

# ------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Peering Configuration
# ------------------------------------------------------------------------------

variable "create_peering" {
  description = "Create VPC peering connection between ODB network and a VPC. Requires either create_vpc=true or existing_vpc_id."
  type        = bool
  default     = false
}

variable "existing_vpc_id" {
  description = "ID of an existing VPC to peer with the ODB network. Required when create_peering is true and create_vpc is false."
  type        = string
  default     = null

  validation {
    condition     = var.existing_vpc_id == null || can(regex("^vpc-[a-f0-9]+$", var.existing_vpc_id))
    error_message = "existing_vpc_id must be a valid VPC ID (e.g., vpc-0123456789abcdef0)."
  }
}

# ------------------------------------------------------------------------------
# OPTIONAL VARIABLES - Timeouts
# ------------------------------------------------------------------------------

variable "timeouts" {
  description = "Custom timeouts for resource operations. Exadata infrastructure provisioning can take several hours."
  type = object({
    create = optional(string, "24h")
    update = optional(string, "2h")
    delete = optional(string, "8h")
  })
  default = {}
}
