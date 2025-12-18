# Terraform Module for Oracle Database@AWS - Exadata Infrastructure and Networking

Terraform module to provision Oracle Database@AWS Exadata Infrastructure, including the ODB Network, Cloud Exadata hardware, and optional VPC peering for application connectivity.

## Features

- **ODB Network**: Oracle-managed network with configurable client and backup subnets
- **Exadata Infrastructure**: Configurable shapes (X11M, X9M, X8M), compute/storage counts
- **Optional VPC**: Sample VPC for testing and demos
- **Optional Peering**: Connect ODB network to existing or newly created VPCs
- **S3 & Zero-ETL Access**: Enable AWS service integrations

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Region                              │
│  ┌─────────────────────┐         ┌─────────────────────────┐    │
│  │   Application VPC   │         │      ODB Network        │    │
│  │   (yours or created)│◄───────►│  ┌─────────────────┐    │    │
│  │                     │ Peering │  │ Client Subnet   │    │    │
│  │  ┌──────────────┐   │         │  └─────────────────┘    │    │
│  │  │ App Subnet   │   │         │  ┌─────────────────┐    │    │
│  │  └──────────────┘   │         │  │ Backup Subnet   │    │    │
│  └─────────────────────┘         │  └─────────────────┘    │    │
│                                  │          │              │    │
│                                  │          ▼              │    │
│                                  │  ┌─────────────────┐    │    │
│                                  │  │    Exadata      │    │    │
│                                  │  │ Infrastructure  │    │    │
│                                  │  └─────────────────┘    │    │
│                                  └─────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

## Usage

### Minimal Example (Infrastructure Only)

```hcl
module "exadata" {
  source = "github.com/vmleon/oracle-database-aws-exadata-infrastructure?ref=v1.0.0"

  name_prefix       = "myapp"
  aws_region        = "us-east-1"
  availability_zone = "us-east-1a"
  contact_email     = "dba-team@example.com"
}
```

### With VPC Peering to Existing VPC

```hcl
module "exadata" {
  source = "github.com/vmleon/oracle-database-aws-exadata-infrastructure?ref=v1.0.0"

  name_prefix       = "prod"
  aws_region        = "us-east-1"
  availability_zone = "us-east-1a"
  contact_email     = "dba-team@example.com"

  # Peer with your existing application VPC
  create_peering  = true
  existing_vpc_id = "vpc-0123456789abcdef0"

  # Enable S3 access for data import/export
  s3_access = "ENABLED"

  tags = {
    environment = "production"
    cost-center = "database-team"
  }
}
```

### Complete Example (Demo VPC + Peering)

```hcl
module "exadata" {
  source = "github.com/vmleon/oracle-database-aws-exadata-infrastructure?ref=v1.0.0"

  name_prefix       = "demo"
  name_suffix       = "dev"
  aws_region        = "us-west-2"
  availability_zone = "us-west-2a"
  contact_email     = "demo@example.com"

  # Exadata configuration
  exadata_shape        = "Exadata.X11M"
  compute_count        = 2
  storage_count        = 3
  database_server_type = "X11M"
  storage_server_type  = "X11M-HC"

  # Network configuration
  client_subnet_cidr = "10.33.1.0/24"
  backup_subnet_cidr = "10.33.0.0/24"

  # Create demo VPC and peer with it
  create_vpc      = true
  create_peering  = true
  vpc_cidr        = "10.34.0.0/16"
  app_subnet_cidr = "10.34.1.0/24"

  tags = {
    environment = "development"
    project     = "oracle-migration"
  }
}
```

<!-- BEGIN_TF_DOCS -->
# Oracle Database@AWS Exadata Infrastructure

Terraform module for provisioning Oracle Database@AWS Exadata Infrastructure with ODB Network. Optionally creates sample VPC and peering connection for connectivity.

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

## Features

- **ODB Network**: Creates the required Oracle Database network with client and backup subnets
- **Exadata Infrastructure**: Provisions cloud Exadata infrastructure with configurable shape and capacity
- **Flexible Peering**: Optional VPC peering - bring your own VPC or create a sample one for testing
- **S3 & Zero-ETL**: Optional integration with AWS S3 and Zero-ETL analytics services
- **Maintenance Control**: Configurable maintenance windows and patching modes

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Region                              │
│  ┌──────────────────────┐      ┌─────────────────────────────┐ │
│  │   Application VPC    │      │       ODB Network           │ │
│  │   (yours or sample)  │◄────►│  ┌─────────────────────┐    │ │
│  │                      │      │  │  Client Subnet      │    │ │
│  │  ┌────────────────┐  │      │  │  (Database Access)  │    │ │
│  │  │  App Subnet    │  │      │  └─────────────────────┘    │ │
│  │  │                │  │      │  ┌─────────────────────┐    │ │
│  │  └────────────────┘  │      │  │  Backup Subnet      │    │ │
│  └──────────────────────┘      │  │  (OCI Connectivity) │    │ │
│           ▲                    │  └─────────────────────┘    │ │
│           │                    └──────────────┬──────────────┘ │
│           │                                   │                │
│           │ Peering                           │                │
│           │ (optional)                        ▼                │
│           │                    ┌─────────────────────────────┐ │
│           └────────────────────│   Exadata Infrastructure    │ │
│                                │  ┌───────┐ ┌───────┐        │ │
│                                │  │DB Srv │ │DB Srv │ ...    │ │
│                                │  └───────┘ └───────┘        │ │
│                                │  ┌───────┐ ┌───────┐        │ │
│                                │  │Storage│ │Storage│ ...    │ │
│                                │  └───────┘ └───────┘        │ │
│                                └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Prerequisites

- AWS account with Oracle Database@AWS enabled
- Terraform >= 1.5.0
- AWS provider >= 6.25.0
- Availability zone that supports Oracle Database@AWS

## Important Notes

> **Provider Configuration**: Do NOT configure the AWS provider inside this module. Configure it in your root module and this module will inherit that configuration. See the [examples](./examples/) directory for proper usage.

> **Provisioning Time**: Exadata Infrastructure creation takes approximately 4-8 hours. Plan accordingly.

> **CIDR Planning**: Ensure client_subnet_cidr and backup_subnet_cidr don't overlap with your existing VPCs if you plan to peer. The module validates that these CIDRs don't overlap.

> **Security Groups**: The sample VPC does not create security groups. You must create security groups that allow traffic between your applications and the Oracle database (typically port 1521).

> **Costs**: Exadata Infrastructure incurs significant costs. Review [Oracle Database@AWS pricing](https://aws.amazon.com/oracle-database/pricing/) before deploying.

## Examples

See the [examples](./examples/) directory for complete usage examples:

- [basic](./examples/basic/) - Simple deployment with sample VPC for testing
- [with-existing-vpc](./examples/with-existing-vpc/) - Production deployment peered with existing VPC

## Usage

```hcl
module "exadata" {
  source = "github.com/vmleon/oracle-database-aws-exadata-infrastructure"

  name_prefix       = "myapp"
  aws_region        = "us-east-1"
  availability_zone = "us-east-1a"
  contact_email     = "dba-team@example.com"
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.25.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.25.0 |

## Resources

| Name | Type |
|------|------|
| [aws_odb_cloud_exadata_infrastructure.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/odb_cloud_exadata_infrastructure) | resource |
| [aws_odb_network.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/odb_network) | resource |
| [aws_odb_network_peering_connection.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/odb_network_peering_connection) | resource |
| [aws_subnet.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.application](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_availability_zone.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zone) | data source |
| [aws_odb_db_servers.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/odb_db_servers) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_subnet_cidr"></a> [app\_subnet\_cidr](#input\_app\_subnet\_cidr) | CIDR block for the application subnet in the sample VPC. Only used when create\_vpc is true. | `string` | `"10.34.1.0/24"` | no |
| <a name="input_availability_zone"></a> [availability\_zone](#input\_availability\_zone) | AWS Availability Zone for deployment. Must be in the specified aws\_region and support Oracle Database@AWS. | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region for deployment. Must be a region where Oracle Database@AWS is available. | `string` | n/a | yes |
| <a name="input_backup_subnet_cidr"></a> [backup\_subnet\_cidr](#input\_backup\_subnet\_cidr) | CIDR block for the ODB backup subnet. Must be /24 or larger. This subnet handles database backup traffic to Oracle Cloud. | `string` | `"10.33.0.0/24"` | no |
| <a name="input_client_subnet_cidr"></a> [client\_subnet\_cidr](#input\_client\_subnet\_cidr) | CIDR block for the ODB client subnet. Must be /24 or larger. This subnet handles database client connections. | `string` | `"10.33.1.0/24"` | no |
| <a name="input_compute_count"></a> [compute\_count](#input\_compute\_count) | Number of database servers (compute nodes). Minimum 2 for high availability. Scale based on CPU and memory requirements. | `number` | `2` | no |
| <a name="input_contact_email"></a> [contact\_email](#input\_contact\_email) | Email address for Oracle Cloud Infrastructure notifications. Required by Oracle for infrastructure alerts and maintenance communications. | `string` | n/a | yes |
| <a name="input_create_peering"></a> [create\_peering](#input\_create\_peering) | Create VPC peering connection between ODB network and a VPC. Requires either create\_vpc=true or existing\_vpc\_id. | `bool` | `false` | no |
| <a name="input_create_vpc"></a> [create\_vpc](#input\_create\_vpc) | Create a sample VPC for connectivity testing. Set to false in production and use existing\_vpc\_id instead. | `bool` | `false` | no |
| <a name="input_database_server_type"></a> [database\_server\_type](#input\_database\_server\_type) | Database server model. Must align with exadata\_shape: X11M for Exadata.X11M, X9M for Exadata.X9M, X8M for Exadata.X8M. | `string` | `"X11M"` | no |
| <a name="input_exadata_shape"></a> [exadata\_shape](#input\_exadata\_shape) | Exadata infrastructure shape. Determines the generation and capabilities of the hardware. | `string` | `"Exadata.X11M"` | no |
| <a name="input_existing_vpc_id"></a> [existing\_vpc\_id](#input\_existing\_vpc\_id) | ID of an existing VPC to peer with the ODB network. Required when create\_peering is true and create\_vpc is false. | `string` | `null` | no |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | Maintenance window configuration for patching and updates. | <pre>object({<br/>    preference                       = optional(string, "NO_PREFERENCE")<br/>    patching_mode                    = optional(string, "ROLLING")<br/>    is_custom_action_timeout_enabled = optional(bool, false)<br/>    custom_action_timeout_in_mins    = optional(number, 15)<br/>  })</pre> | `{}` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for all resource names. Use lowercase alphanumeric characters and hyphens only. | `string` | n/a | yes |
| <a name="input_name_suffix"></a> [name\_suffix](#input\_name\_suffix) | Optional suffix for resource names. Useful for ensuring uniqueness across deployments. | `string` | `""` | no |
| <a name="input_s3_access"></a> [s3\_access](#input\_s3\_access) | Enable S3 access from ODB network for data import/export operations. | `string` | `"DISABLED"` | no |
| <a name="input_storage_count"></a> [storage\_count](#input\_storage\_count) | Number of storage servers. Minimum 3 for data redundancy. Scale based on storage capacity and IOPS requirements. | `number` | `3` | no |
| <a name="input_storage_server_type"></a> [storage\_server\_type](#input\_storage\_server\_type) | Storage server model. HC variants provide higher capacity. Must align with exadata\_shape generation. | `string` | `"X11M-HC"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources. Recommended: include 'environment', 'owner', and 'cost-center' tags for production. | `map(string)` | `{}` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Custom timeouts for resource operations. Exadata infrastructure provisioning can take several hours. | <pre>object({<br/>    create = optional(string, "24h")<br/>    update = optional(string, "2h")<br/>    delete = optional(string, "8h")<br/>  })</pre> | `{}` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block for the sample VPC. Only used when create\_vpc is true. | `string` | `"10.34.0.0/16"` | no |
| <a name="input_zero_etl_access"></a> [zero\_etl\_access](#input\_zero\_etl\_access) | Enable Zero-ETL access for real-time data integration with AWS analytics services. | `string` | `"DISABLED"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_app_subnet_id"></a> [app\_subnet\_id](#output\_app\_subnet\_id) | ID of the application subnet. Null if create\_vpc is false. |
| <a name="output_availability_zone"></a> [availability\_zone](#output\_availability\_zone) | Availability Zone where resources are deployed. |
| <a name="output_availability_zone_id"></a> [availability\_zone\_id](#output\_availability\_zone\_id) | Availability Zone ID (consistent across AWS accounts). |
| <a name="output_cpu_count"></a> [cpu\_count](#output\_cpu\_count) | Total CPU cores allocated to the Exadata Infrastructure. |
| <a name="output_data_storage_size_in_tbs"></a> [data\_storage\_size\_in\_tbs](#output\_data\_storage\_size\_in\_tbs) | Total data storage capacity in TB. |
| <a name="output_db_server_ids"></a> [db\_server\_ids](#output\_db\_server\_ids) | List of database server IDs. Use these when creating a VM Cluster. |
| <a name="output_db_server_version"></a> [db\_server\_version](#output\_db\_server\_version) | Software version running on database servers. |
| <a name="output_exadata_infrastructure_arn"></a> [exadata\_infrastructure\_arn](#output\_exadata\_infrastructure\_arn) | ARN of the Exadata Infrastructure. |
| <a name="output_exadata_infrastructure_id"></a> [exadata\_infrastructure\_id](#output\_exadata\_infrastructure\_id) | ID of the Exadata Infrastructure. |
| <a name="output_exadata_infrastructure_ocid"></a> [exadata\_infrastructure\_ocid](#output\_exadata\_infrastructure\_ocid) | Oracle Cloud Infrastructure OCID of the Exadata Infrastructure. |
| <a name="output_max_cpu_count"></a> [max\_cpu\_count](#output\_max\_cpu\_count) | Maximum CPU cores available on the Exadata Infrastructure. |
| <a name="output_memory_size_in_gbs"></a> [memory\_size\_in\_gbs](#output\_memory\_size\_in\_gbs) | Total memory allocated in GB. |
| <a name="output_oci_compartment_ocid"></a> [oci\_compartment\_ocid](#output\_oci\_compartment\_ocid) | OCI compartment OCID containing the Exadata Infrastructure. |
| <a name="output_oci_region"></a> [oci\_region](#output\_oci\_region) | OCI region where the Exadata Infrastructure is registered. |
| <a name="output_oci_tenant"></a> [oci\_tenant](#output\_oci\_tenant) | OCI tenant name. |
| <a name="output_oci_url"></a> [oci\_url](#output\_oci\_url) | Direct link to the Exadata Infrastructure in the OCI Console. |
| <a name="output_odb_network_arn"></a> [odb\_network\_arn](#output\_odb\_network\_arn) | ARN of the ODB Network. |
| <a name="output_odb_network_id"></a> [odb\_network\_id](#output\_odb\_network\_id) | ID of the ODB Network. |
| <a name="output_peering_connection_arn"></a> [peering\_connection\_arn](#output\_peering\_connection\_arn) | ARN of the ODB Network Peering Connection. Null if create\_peering is false. |
| <a name="output_peering_connection_id"></a> [peering\_connection\_id](#output\_peering\_connection\_id) | ID of the ODB Network Peering Connection. Null if create\_peering is false. |
| <a name="output_storage_server_version"></a> [storage\_server\_version](#output\_storage\_server\_version) | Software version running on storage servers. |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | CIDR block of the created VPC. Null if create\_vpc is false. |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the created VPC. Null if create\_vpc is false. |
<!-- END_TF_DOCS -->

## Next Steps After Deployment

After the Exadata Infrastructure is provisioned, you'll typically:

1. **Create a VM Cluster** using the `db_server_ids` output
2. **Create Oracle Databases** on the VM Cluster
3. **Configure application connectivity** via the peered VPC

## Related Resources

- [Oracle Database@AWS Documentation](https://docs.oracle.com/en/cloud/paas/exadata-cloud-at-aws/)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Module Best Practices](https://developer.hashicorp.com/terraform/language/modules/develop)

## License

Apache 2.0 - See [LICENSE](LICENSE) for details.

## Author

Victor Martinez Leon ([@vmleon](https://github.com/vmleon))
