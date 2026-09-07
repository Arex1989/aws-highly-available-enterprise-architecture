# AWS Highly Available Enterprise Architecture

> **Production-style AWS cloud engineering portfolio demonstrating highly available architecture, multi-AZ networking, private compute, load balancing, Auto Scaling, IAM, monitoring, security, Infrastructure as Code, resilience testing, and FinOps.**

## Executive Summary

This project demonstrates the design, deployment, operation, validation, and controlled retirement of a highly available AWS enterprise application environment.

The architecture is designed to eliminate common single points of failure by distributing workloads across multiple Availability Zones, placing application compute in private subnets, distributing traffic through an Application Load Balancer, and automatically replacing unhealthy compute resources.

The project will be implemented through hands-on AWS engineering and progressively managed through Terraform Infrastructure as Code.

## Business Scenario

A fictional enterprise requires a secure and highly available AWS environment for hosting a business application.

The application must remain available when an individual compute instance becomes unhealthy and should tolerate infrastructure failure within a single Availability Zone.

The solution must provide:

- Multi-Availability-Zone architecture
- Segmented public and private networking
- Private application compute
- Controlled outbound Internet connectivity
- Load-balanced inbound application traffic
- Automatic compute replacement and scaling
- Least-privilege identity and access management
- Centralized monitoring and alerting
- Secure cloud storage
- Infrastructure as Code
- Failure and recovery validation
- Cost monitoring and budget controls

## Architecture Requirements

### Networking

- Dedicated AWS VPC
- Two Availability Zones
- Two public subnets
- Two private application subnets
- Internet Gateway for public connectivity
- NAT-based outbound connectivity for private workloads
- Dedicated route tables
- No public IP addresses on application EC2 instances

### Compute & High Availability

- Linux EC2 application workloads
- Application Load Balancer
- Target groups and health checks
- Auto Scaling Group
- Multi-AZ workload distribution
- Automated replacement of unhealthy instances

### Security

- Security Groups using least-privilege traffic flows
- IAM roles instead of embedded AWS credentials
- AWS Systems Manager for administrative access where practical
- S3 Block Public Access
- Encryption where appropriate

### Monitoring & Operations

- Amazon CloudWatch metrics and alarms
- Application and infrastructure health monitoring
- SNS notification workflow
- Operational failure testing
- Recovery validation

### Infrastructure as Code

- Terraform-managed AWS infrastructure
- Version-controlled infrastructure definitions
- Repeatable deployment workflow
- Terraform validation and planning
- State reconciliation
- Controlled infrastructure decommissioning

## Initial Network Design

**Region:** Europe (Frankfurt) - `eu-central-1`

**VPC CIDR:** `10.20.0.0/16`

| Availability Zone | Subnet Type | CIDR |
|---|---|---|
| `eu-central-1a` | Public | `10.20.1.0/24` |
| `eu-central-1a` | Private Application | `10.20.11.0/24` |
| `eu-central-1b` | Public | `10.20.2.0/24` |
| `eu-central-1b` | Private Application | `10.20.12.0/24` |

Availability Zone assignments were validated against the AWS account before deployment.

Available Frankfurt Availability Zones were confirmed as `eu-central-1a`, `eu-central-1b`, and `eu-central-1c`. The architecture uses `eu-central-1a` and `eu-central-1b` for the initial two-AZ deployment.

## Security & Cost Controls

Phase 2 established the AWS account security and FinOps baseline before infrastructure deployment.

### Identity & Access

- Root account protected with MFA
- No root access keys created
- Root CLI session removed from routine project administration
- IAM Identity Center enabled in `eu-central-1`
- Dedicated administrative identity configured through IAM Identity Center
- MFA enabled for the administrative identity
- `AdministratorAccess` permission set configured with a one-hour session duration
- AWS CLI authenticated through IAM Identity Center using temporary SSO credentials
- CLI identity validated through AWS STS
- Default project region configured as `eu-central-1`

### Cost Governance

- AWS Billing and Cost Management configured
- Valid account payment method confirmed
- Recurring monthly AWS cost budget configured at `$50`
- Account-wide budget scope across AWS services
- Cost aggregation based on unblended costs
- Actual-cost alert at 50% (`$25`)
- Actual-cost alert at 75% (`$37.50`)
- Actual-cost alert at 90% (`$45`)
- Forecasted-cost alert at 100% (`$50`)
- Email notifications configured for budget thresholds
- AWS Cost Anomaly Detection monitor active
- Budget actions intentionally left disabled to prevent automated disruption during resilience testing

## VPC & CIDR Design

The application network uses a dedicated RFC1918 IPv4 address space designed for multi-AZ segmentation and future expansion.

**VPC CIDR:** `10.20.0.0/16`

The VPC provides 65,536 IPv4 addresses and is divided into purpose-specific `/24` subnet ranges.

### Initial Subnet Allocation

| Availability Zone | Network Tier | CIDR | Total Addresses | AWS-Usable Addresses |
|---|---|---|---:|---:|
| `eu-central-1a` | Public | `10.20.1.0/24` | 256 | 251 |
| `eu-central-1b` | Public | `10.20.2.0/24` | 256 | 251 |
| `eu-central-1a` | Private Application | `10.20.11.0/24` | 256 | 251 |
| `eu-central-1b` | Private Application | `10.20.12.0/24` | 256 | 251 |

### Addressing Convention

Address space is intentionally grouped by network function to support predictable future expansion:

- `10.20.1.0/24` - `10.20.9.0/24`: Public / edge tier
- `10.20.11.0/24` - `10.20.19.0/24`: Private application tier
- `10.20.21.0/24` - `10.20.29.0/24`: Reserved private database tier
- `10.20.31.0/24` - `10.20.39.0/24`: Reserved management / operations tier
- `10.20.41.0/24` - `10.20.49.0/24`: Reserved endpoint / internal services tier

Reserved ranges represent the addressing strategy only and are not provisioned until required.

### Network Validation

The CIDR design was validated before deployment:

- All initial subnets are contained within `10.20.0.0/16`
- All initial subnet overlap tests returned false
- Each `/24` provides 251 AWS-usable IPv4 addresses
- Frankfurt Availability Zones were validated through the AWS CLI
- `eu-central-1a` and `eu-central-1b` were selected for the initial deployment
- Existing Frankfurt VPC CIDRs were inspected before deployment
- The existing default VPC uses `172.31.0.0/16`
- The proposed `10.20.0.0/16` VPC does not overlap the existing default VPC


## Subnets, Routing & Gateways

Phase 4 implemented the multi-AZ network topology defined during the VPC and CIDR design phase.

### Deployed Subnets

| Availability Zone | Network Tier | CIDR |
|---|---|---|
| `eu-central-1a` | Public | `10.20.1.0/24` |
| `eu-central-1b` | Public | `10.20.2.0/24` |
| `eu-central-1a` | Private Application | `10.20.11.0/24` |
| `eu-central-1b` | Private Application | `10.20.12.0/24` |

### Internet Connectivity

- Internet Gateway `igw-enterprise-dev` created and attached to the enterprise VPC
- Dedicated public route table `rtb-public-enterprise-dev` created
- Public default route configured as `0.0.0.0/0 -> Internet Gateway`
- Both public subnets explicitly associated with the public route table
- Automatic public IPv4 assignment remains disabled

### Private Application Routing

- Dedicated private application route table `rtb-private-app-enterprise-dev` created
- Both private application subnets explicitly associated with the private route table
- Private route table currently contains only the `10.20.0.0/16` local VPC route
- No direct Internet Gateway route exists for the private application tier

### NAT Strategy

The production high-availability design uses one NAT Gateway per Availability Zone to avoid a single-AZ dependency for private outbound connectivity.

NAT Gateways are intentionally deferred during the current lab stage to control recurring infrastructure cost. They can be introduced when private workload outbound connectivity is required.

This demonstrates a deliberate trade-off between production resilience requirements and development-environment cost governance.


## Network Security

Phase 5 implemented workload-level network security using dedicated AWS Security Groups and a least-privilege traffic model.

### Security Group Architecture

| Security Group | Purpose | Inbound Access |
|---|---|---|
| `sg-alb-enterprise-dev` | Public Application Load Balancer | TCP/80 from `0.0.0.0/0` |
| `sg-app-enterprise-dev` | Private application workloads | TCP/8080 from ALB security group only |

Traffic flow:

`Internet -> TCP/80 -> ALB Security Group -> TCP/8080 -> Application Security Group`

### Least-Privilege Controls

- Application workloads are not directly exposed to the Internet
- TCP/8080 is permitted only through a security-group reference from the ALB tier
- No SSH/TCP 22 Internet access is configured
- No unrestricted inbound rule exists on the application security group
- Security groups provide stateful workload-level traffic control
- Default outbound access is retained during the development stage

### Administrative Access Strategy

Direct Internet-facing SSH access is intentionally excluded.

Administrative access to EC2 workloads will use AWS Systems Manager Session Manager where practical, reducing the requirement for inbound management ports, bastion hosts, and SSH key distribution.

### Network ACL Strategy

The VPC default Network ACL was inspected and retained for the development environment.

All four project subnets currently use the default NACL. Security Groups provide the primary workload-level access controls.

Custom restrictive NACLs are intentionally deferred because NACLs are stateless and require explicit handling of return and ephemeral traffic. Production environments can introduce subnet-level NACL controls where additional defense-in-depth requirements justify the operational complexity.

### Transport Security Roadmap

HTTP/TCP 80 is enabled for the development-stage ALB path.

The production architecture will use HTTPS/TCP 443 with AWS Certificate Manager (ACM), with HTTP redirected to HTTPS when the Application Load Balancer and DNS configuration are deployed.

## Project Phases

| Phase | Engineering Stage | Status |
|---|---|---|
| 1 | Architecture & Requirements | ✅ Complete |
| 2 | AWS Account & Cost Controls | ✅ Complete |
| 3 | VPC & CIDR Design | ✅ Complete |
| 4 | Subnets, Routing & Gateways | ✅ Complete |
| 5 | Network Security | ✅ Complete |
| 6 | EC2 Compute & IAM | 🚧 In Progress |
| 7 | Application Load Balancer | ⬜ Not Started |
| 8 | Auto Scaling & High Availability | ⬜ Not Started |
| 9 | Storage & Application Configuration | ⬜ Not Started |
| 10 | CloudWatch Monitoring & Alerting | ⬜ Not Started |
| 11 | High Availability & Failure Testing | ⬜ Not Started |
| 12 | Terraform Infrastructure as Code | ⬜ Not Started |
| 13 | Documentation, Cost Review & Decommissioning | ⬜ Not Started |

## Project Status

🟡 **In Progress**

**Current Phase:** EC2 Compute & IAM
