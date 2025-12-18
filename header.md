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
