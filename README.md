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

## Requirements

| Name      | Version   |
| --------- | --------- |
| terraform | >= 1.5.0  |
| aws       | >= 5.70.0 |

## Inputs

| Name                 | Description                        | Type          | Default          | Required |
| -------------------- | ---------------------------------- | ------------- | ---------------- | :------: |
| name_prefix          | Prefix for all resource names      | `string`      | n/a              |   yes    |
| aws_region           | AWS region for deployment          | `string`      | n/a              |   yes    |
| contact_email        | Email for OCI notifications        | `string`      | n/a              |   yes    |
| name_suffix          | Optional suffix for resource names | `string`      | `""`             |    no    |
| availability_zone    | AWS Availability Zone              | `string`      | `null`           |    no    |
| tags                 | Tags to apply to all resources     | `map(string)` | `{}`             |    no    |
| client_subnet_cidr   | CIDR for ODB client subnet         | `string`      | `"10.33.1.0/24"` |    no    |
| backup_subnet_cidr   | CIDR for ODB backup subnet         | `string`      | `"10.33.0.0/24"` |    no    |
| s3_access            | Enable S3 access                   | `string`      | `"DISABLED"`     |    no    |
| zero_etl_access      | Enable Zero-ETL access             | `string`      | `"DISABLED"`     |    no    |
| exadata_shape        | Exadata infrastructure shape       | `string`      | `"Exadata.X11M"` |    no    |
| compute_count        | Number of database servers         | `number`      | `2`              |    no    |
| storage_count        | Number of storage servers          | `number`      | `3`              |    no    |
| database_server_type | Database server model              | `string`      | `"X11M"`         |    no    |
| storage_server_type  | Storage server model               | `string`      | `"X11M-HC"`      |    no    |
| maintenance_window   | Maintenance window config          | `object`      | `{}`             |    no    |
| create_vpc           | Create sample VPC                  | `bool`        | `false`          |    no    |
| vpc_cidr             | CIDR for sample VPC                | `string`      | `"10.34.0.0/16"` |    no    |
| app_subnet_cidr      | CIDR for app subnet                | `string`      | `"10.34.1.0/24"` |    no    |
| create_peering       | Create VPC peering                 | `bool`        | `false`          |    no    |
| existing_vpc_id      | Existing VPC ID to peer with       | `string`      | `null`           |    no    |
| timeouts             | Custom operation timeouts          | `object`      | `{}`             |    no    |

## Outputs

| Name                        | Description                                         |
| --------------------------- | --------------------------------------------------- |
| exadata_infrastructure_id   | ID of the Exadata Infrastructure                    |
| exadata_infrastructure_arn  | ARN of the Exadata Infrastructure                   |
| exadata_infrastructure_ocid | OCI OCID of the Exadata Infrastructure              |
| odb_network_id              | ID of the ODB Network                               |
| odb_network_arn             | ARN of the ODB Network                              |
| db_server_ids               | List of database server IDs for VM Cluster creation |
| cpu_count                   | Total CPU cores allocated                           |
| memory_size_in_gbs          | Memory allocated in GB                              |
| data_storage_size_in_tbs    | Storage capacity in TB                              |
| oci_url                     | Link to OCI Console                                 |
| vpc_id                      | ID of created VPC (if create_vpc=true)              |
| peering_connection_id       | ID of peering connection (if create_peering=true)   |

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
