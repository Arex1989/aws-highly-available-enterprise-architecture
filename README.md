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
| AZ-1 | Public | `10.20.1.0/24` |
| AZ-1 | Private Application | `10.20.11.0/24` |
| AZ-2 | Public | `10.20.2.0/24` |
| AZ-2 | Private Application | `10.20.12.0/24` |

Availability Zone assignments will be validated against the AWS account before deployment.

## Project Phases

| Phase | Engineering Stage | Status |
|---|---|---|
| 1 | Architecture & Requirements | 🚧 In Progress |
| 2 | AWS Account & Cost Controls | ⬜ Not Started |
| 3 | VPC & CIDR Design | ⬜ Not Started |
| 4 | Subnets, Routing & Gateways | ⬜ Not Started |
| 5 | Network Security | ⬜ Not Started |
| 6 | EC2 Compute & IAM | ⬜ Not Started |
| 7 | Application Load Balancer | ⬜ Not Started |
| 8 | Auto Scaling & High Availability | ⬜ Not Started |
| 9 | Storage & Application Configuration | ⬜ Not Started |
| 10 | CloudWatch Monitoring & Alerting | ⬜ Not Started |
| 11 | High Availability & Failure Testing | ⬜ Not Started |
| 12 | Terraform Infrastructure as Code | ⬜ Not Started |
| 13 | Documentation, Cost Review & Decommissioning | ⬜ Not Started |

## Project Status

🟡 **In Progress**

**Current Phase:** Architecture & Requirements
