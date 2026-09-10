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

## EC2 Compute & IAM

Phase 6 deployed and validated the private compute and administrative-access layer across two Availability Zones.

### Compute Architecture

| Instance | Availability Zone | Subnet | Private IP | Public IP |
|---|---|---|---|---|
| `ec2-app-enterprise-1a` | `eu-central-1a` | `10.20.11.0/24` | `10.20.11.119` | None |
| `ec2-app-enterprise-1b` | `eu-central-1b` | `10.20.12.0/24` | `10.20.12.217` | None |

Both instances use Amazon Linux 2023 and the `t3.micro` instance type.

### IAM & Systems Manager

- Dedicated EC2 IAM role `ec2-enterprise-app-role` created
- AWS managed policy `AmazonSSMManagedInstanceCore` attached
- Instance profile `ec2-enterprise-app-profile` created and assigned to the application instances
- Both EC2 instances successfully registered with AWS Systems Manager
- Both nodes validated with SSM `PingStatus: Online`
- Systems Manager administration uses private VPC interface endpoints
- Interactive Session Manager access successfully validated
- No SSH key pair is required for routine administration
- No inbound SSH/TCP 22 rule is configured

### Private Systems Manager Connectivity

Interface VPC endpoints were deployed across both private application subnets for:

- `com.amazonaws.eu-central-1.ssm`
- `com.amazonaws.eu-central-1.ssmmessages`

Private DNS is enabled for both endpoints.

The endpoint security group permits HTTPS/TCP 443 from the application security group, allowing the private EC2 instances to communicate with Systems Manager without requiring public IPv4 addresses or a NAT Gateway.

### Instance Security Controls

- EC2 instances deployed only into private application subnets
- Public IPv4 assignment disabled
- Encrypted `gp3` root volumes configured
- IMDSv2 token enforcement configured with `HttpTokens=required`
- Unauthenticated IMDS request validated to return HTTP `401`
- Application security group remains the workload-level traffic boundary
- Administrative access provided through AWS Systems Manager Session Manager

### Multi-AZ Validation

The compute tier is distributed across:

`eu-central-1a -> 10.20.11.0/24 -> ec2-app-enterprise-1a`

`eu-central-1b -> 10.20.12.0/24 -> ec2-app-enterprise-1b`

This establishes the two-AZ compute foundation required for the Application Load Balancer and subsequent high-availability stages.

## Application Load Balancer

Phase 7 implemented and validated highly available application traffic distribution across two AWS Availability Zones.

### Load Balancer Architecture

- Internet-facing Application Load Balancer `alb-enterprise-app-dev`
- Deployed across `eu-central-1a` and `eu-central-1b`
- Dedicated public subnets used in both Availability Zones
- HTTP/TCP 80 listener configured for the development environment
- Listener forwards requests to the application target group

### Target Group

- Target group `tg-enterprise-app-dev`
- Target protocol: HTTP
- Target port: `8080`
- Health check path: `/`
- Both private EC2 application instances registered successfully
- Both targets validated as `healthy`

### Application Traffic Flow

`Internet -> ALB:80 -> Target Group:8080 -> Private EC2 Application Tier`

The application security group permits TCP/8080 from the ALB security group only. Application instances are not directly exposed to the Internet.

### Multi-AZ Validation

Repeated requests through the public ALB DNS endpoint successfully returned responses from both application nodes:

- `10.20.11.119` in `eu-central-1a`
- `10.20.12.217` in `eu-central-1b`

This validates functional application traffic distribution across both Availability Zones.

### Current Transport Security

HTTP/TCP 80 is intentionally used during the development stage.

The production architecture will use HTTPS/TCP 443 with AWS Certificate Manager (ACM), with HTTP redirected to HTTPS.

## Auto Scaling & High Availability

Phase 8 implemented and validated a multi-AZ Auto Scaling architecture for the private application tier.

### Auto Scaling Architecture

- Auto Scaling Group: `asg-enterprise-app-dev`
- Launch Template: `lt-enterprise-app-dev`
- Minimum capacity: `2`
- Desired capacity: `2`
- Maximum capacity: `4`
- Instances distributed across `eu-central-1a` and `eu-central-1b`
- ELB health checks enabled
- Application instances automatically registered with the existing target group
- Application bootstrap performed automatically through launch-template user data
- EC2 instances remain private with no public IPv4 addresses

### Self-Healing Validation

A controlled EC2 failure was performed by terminating one Auto Scaling-managed application instance.

Failed instance:

`<instance-id>`

Auto Scaling detected the instance failure and automatically launched a replacement:

`<instance-id>`

The replacement instance successfully:

- Bootstrapped the application automatically
- Joined the Auto Scaling Group
- Reached `Healthy / InService`
- Registered with the Application Load Balancer target group
- Passed the ALB health check on TCP/8080
- Registered successfully with AWS Systems Manager
- Reached SSM `PingStatus: Online`

### Multi-AZ Recovery State

Following recovery, application capacity was restored across both Availability Zones:

- `eu-central-1a` — replacement application node — `Healthy / InService`
- `eu-central-1b` — surviving application node — `Healthy / InService`

Auto Scaling capacity remained:

- Minimum: `2`
- Desired: `2`
- Maximum: `4`

### Availability During Failure

Repeated HTTP requests through the public Application Load Balancer continued to succeed during and after the instance replacement.

Traffic was successfully served by:

- `10.20.11.127` — `eu-central-1a`
- `10.20.12.214` — `eu-central-1b`

This validates application availability across multiple Availability Zones and demonstrates automatic EC2 failure recovery without manual instance provisioning.

### High Availability Result

The architecture now demonstrates:

`Instance Failure -> Auto Scaling Detection -> Automatic Replacement -> Application Bootstrap -> ALB Registration -> Health Validation -> Traffic Restoration`

The failed instance remains under Auto Scaling lifecycle management during termination and requires no manual intervention.

## Project Phases

| Phase | Engineering Stage | Status |
|---|---|---|
| 1 | Architecture & Requirements | ✅ Complete |
| 2 | AWS Account & Cost Controls | ✅ Complete |
| 3 | VPC & CIDR Design | ✅ Complete |
| 4 | Subnets, Routing & Gateways | ✅ Complete |
| 5 | Network Security | ✅ Complete |
| 6 | EC2 Compute & IAM | ✅ Complete |
| 7 | Application Load Balancer | ✅ Complete |
| 8 | Auto Scaling & High Availability | ✅ Complete |
| 9 | Storage & Application Configuration | ✅ Complete |
| 10 | CloudWatch Monitoring & Alerting | ✅ Complete |
| 11 | High Availability & Failure Testing | ✅ Complete |
| 12 | Terraform Infrastructure as Code | 🚧 In Progress |
| 13 | Documentation, Cost Review & Decommissioning | ⬜ Not Started |

## Project Status

🟡 **In Progress**

**Current Phase:** Terraform Infrastructure as Code

## Phase 9 — Storage & Application Configuration

Phase 9 implemented centralized, durable application storage and configuration for the highly available application tier.

### S3 Storage Architecture

- Created private S3 bucket `enterprise-app-storage-<account-id>-eu-central-1`
- S3 Block Public Access enabled
- S3 object versioning enabled
- Server-side encryption enabled using AES256 (SSE-S3)
- Application EC2 instances granted least-privilege S3 access through their IAM role
- S3 Gateway VPC Endpoint configured for private application subnet access
- Application instances do not require direct Internet connectivity to access S3

### Persistent Storage Validation

Persistent application data was written from one Auto Scaling instance and successfully retrieved from another instance.

S3 object versioning was validated by overwriting the same object and independently retrieving both historical versions:

- Version 1: `Phase 9 persistent storage test written by Instance 1`
- Version 2: `Phase 9 VERSION 2 written by Instance 2`

This demonstrated durable application data independent of individual EC2 instance lifecycle.

### Centralized Application Configuration

A versioned application configuration object was created at:

`application-config/app-config.json`

The configuration defines:

- Application environment: `dev`
- AWS Region: `eu-central-1`
- Application listener: TCP/8080
- Storage backend: Amazon S3
- High availability enabled

Both application nodes successfully retrieved the same configuration from S3.

### Launch Template Integration

Launch Template `lt-enterprise-app-dev` Version 2 was created with automated S3 configuration retrieval during instance bootstrap.

New application instances automatically:

1. Create the application configuration directory.
2. Retrieve `app-config.json` from private S3.
3. Load the configuration into the Python application.
4. Start the application through systemd.
5. Be automatically registered with the Application Load Balancer target group through the Auto Scaling Group.

The locally validated bootstrap script was compared against the AWS-stored Launch Template user data and produced an exact integrity match.

### Rolling Deployment Validation

The Auto Scaling Group was updated from Launch Template Version 1 to Version 2.

An Auto Scaling Instance Refresh performed a controlled rolling replacement, after which full application capacity and ALB health were restored across both Availability Zones.

Final refresh state:

- Status: `Successful`
- Completion: `100%`
- Instances remaining to update: `0`
- Two Launch Template Version 2 instances
- Instances distributed across `eu-central-1a` and `eu-central-1b`
- Both instances `Healthy / InService`

### End-to-End Validation

Both replacement instances successfully demonstrated:

- Automatic S3 configuration retrieval during bootstrap
- Active `enterprise-app` systemd service
- Application listening on TCP/8080
- Configuration-driven application behavior
- S3 storage backend configuration
- Successful ALB health checks

Repeated requests through the public Application Load Balancer returned responses from both application nodes:

`Internet -> ALB:80 -> Target Group:8080 -> Auto Scaling EC2 -> S3 centralized configuration`

Both target-group members were validated as `healthy`.


## Phase 10 – CloudWatch Monitoring & Alerting

Phase 10 implemented centralized operational monitoring, alerting, notification, and visualization for the highly available application architecture.

### Application Load Balancer Monitoring

CloudWatch metrics for the Application Load Balancer and target group were validated, including:

- `RequestCount` – application traffic through the ALB
- `TargetResponseTime` – backend application response latency
- `HTTPCode_Target_5XX_Count` – HTTP 5XX responses generated by application targets
- `HealthyHostCount` – healthy application targets
- `UnHealthyHostCount` – unhealthy application targets

Test traffic was generated through the public Application Load Balancer to validate CloudWatch metric ingestion.

### CloudWatch Alarms

Three operational CloudWatch alarms were configured:

| Alarm | Metric | Threshold / Evaluation |
|---|---|---|
| `enterprise-app-unhealthy-targets` | `UnHealthyHostCount` | >= 1 for 2 consecutive 60-second periods |
| `enterprise-app-target-5xx-errors` | `HTTPCode_Target_5XX_Count` | >= 5 during a 300-second period |
| `enterprise-app-high-latency` | `TargetResponseTime` | >= 1 second for 2 consecutive 60-second periods |

Missing metric data is treated as `notBreaching` to prevent false alarms during periods without application traffic.

At final validation, all three production alarms were in the `OK` state.

### SNS Alerting

An Amazon SNS topic named:

`enterprise-app-cloudwatch-alerts`

was created as the notification channel for CloudWatch alarms.

A confirmed email subscription was configured and validated. Alarm and OK state transitions are routed through the SNS topic.

End-to-end alert delivery was tested using a temporary low-threshold request-count alarm. Generated ALB traffic caused the alarm to transition into the `ALARM` state and SNS notifications were successfully delivered by email.

The temporary validation alarm was removed after testing.

### CloudWatch Operations Dashboard

A CloudWatch dashboard named:

`enterprise-app-operations`

was deployed for centralized operational visibility.

The dashboard contains seven widgets:

1. Dashboard Header
2. Application Request Traffic
3. Target Response Time
4. Target 5XX Errors
5. Target Health
6. Application Alarm Status
7. Auto Scaling Capacity

The deployed dashboard was retrieved from AWS after creation and validated with no dashboard validation errors.

### EC2 Monitoring

Native `AWS/EC2` CloudWatch metrics were validated for both Auto Scaling application instances.

Available telemetry includes:

- `CPUUtilization`
- `NetworkIn`
- `NetworkOut`
- `NetworkPacketsIn`
- `NetworkPacketsOut`
- `StatusCheckFailed`
- `StatusCheckFailed_Instance`
- `StatusCheckFailed_System`
- EBS performance metrics
- CPU credit metrics

This provides infrastructure-level telemetry independently of individual application monitoring.

### Auto Scaling Monitoring

One-minute Auto Scaling group metric collection was enabled for:

- `GroupDesiredCapacity`
- `GroupInServiceInstances`
- `GroupTotalInstances`
- `GroupPendingInstances`
- `GroupTerminatingInstances`

The validated healthy baseline was:

| Metric | Value |
|---|---:|
| Desired Capacity | 2 |
| In-Service Instances | 2 |
| Total Instances | 2 |
| Pending Instances | 0 |
| Terminating Instances | 0 |

This provides fleet-level monitoring that remains valid as EC2 instances are replaced by Auto Scaling.

### Final Phase 10 Validation

The final monitoring audit confirmed:

- Both application targets `healthy`
- Both application instances `InService`
- Application instances distributed across `eu-central-1a` and `eu-central-1b`
- All three production CloudWatch alarms in `OK`
- Confirmed SNS email notification subscription
- Successful end-to-end alarm email delivery
- Five Auto Scaling group metrics enabled at one-minute granularity
- Auto Scaling desired and in-service capacity both equal to `2`
- No pending or terminating instances
- Seven-widget CloudWatch operations dashboard deployed successfully
- Dashboard returned no validation errors

Phase 10 therefore established an operational observability layer across:

`Application Load Balancer -> Target Group -> Auto Scaling EC2 -> CloudWatch Metrics -> CloudWatch Alarms -> SNS Notifications -> Operations Dashboard`

## Phase 11 - High Availability & Failure Testing

Phase 11 validated the application's resilience, automatic recovery, and continued availability during infrastructure and application-level failures.

### Pre-Failure Baseline

Before failure testing, the environment was validated with:

- Auto Scaling minimum capacity: `2`
- Auto Scaling desired capacity: `2`
- Auto Scaling maximum capacity: `4`
- Two EC2 application instances in `InService`
- Instances distributed across `eu-central-1a` and `eu-central-1b`
- Both Application Load Balancer targets reporting `healthy`
- Application traffic successfully distributed between both instances

This established the healthy baseline for controlled failure testing.

### EC2 Instance Failure Test

A running EC2 instance in the Auto Scaling group was deliberately terminated to simulate infrastructure failure.

The failure test demonstrated the following recovery sequence:

1. The selected EC2 instance transitioned from `running` to `shutting-down`.
2. Auto Scaling detected the loss of capacity.
3. A replacement EC2 instance was launched automatically.
4. The replacement instance executed its bootstrap configuration.
5. Application configuration was retrieved from Amazon S3.
6. The application service started successfully.
7. The replacement instance registered with the target group.
8. The target progressed through initial health checks and became `healthy`.
9. Desired capacity returned to `2`.
10. Application requests continued to be served through the Application Load Balancer.

The final state again contained two healthy `InService` application instances distributed across both Availability Zones.

### Application Service Failure Test

A second failure scenario tested application-level self-healing without manually terminating the EC2 instance.

AWS Systems Manager Run Command was used to stop the `enterprise-app` service on one managed EC2 instance.

The SSM command completed successfully and confirmed the application service state as:

`inactive`

The Application Load Balancer health checks subsequently detected that the instance could no longer serve the application.

The Auto Scaling group responded to the ELB health-check failure by:

1. Marking the affected instance unhealthy.
2. Taking the unhealthy instance out of service.
3. Launching a replacement EC2 instance.
4. Allowing the failed instance to enter termination and target deregistration.
5. Bootstrapping the replacement application instance.
6. Registering the replacement with the target group.
7. Returning the replacement target to `healthy`.

Auto Scaling activity history confirmed that the replacement was launched specifically because an unhealthy instance required replacement.

### Availability During Recovery

Application requests were continuously sent through the public Application Load Balancer while failure recovery was taking place.

Traffic continued to receive valid responses from healthy targets while unhealthy or terminating targets were removed from service.

This demonstrated that the Application Load Balancer and multi-AZ Auto Scaling architecture could maintain application availability while individual application instances failed and were replaced.

### Systems Manager Validation

Replacement instances successfully registered with AWS Systems Manager.

The final managed-instance validation confirmed both active application instances were:

- `Online`
- Running Amazon Linux
- Managed by the SSM Agent

This provides an administrative control path without requiring direct SSH access to the application instances.

### Final Self-Healing Audit

The final Phase 11 audit confirmed:

- Auto Scaling minimum capacity: `2`
- Auto Scaling desired capacity: `2`
- Auto Scaling maximum capacity: `4`
- Two healthy EC2 instances in `InService`
- Instances distributed across `eu-central-1a` and `eu-central-1b`
- Both target-group members `healthy`
- Application traffic successfully served through the ALB
- Failed instances automatically removed and replaced
- Replacement instances successfully bootstrapped
- Auto Scaling recovery activities completed successfully
- `enterprise-app-unhealthy-targets` alarm: `OK`
- `enterprise-app-target-5xx-errors` alarm: `OK`
- `enterprise-app-high-latency` alarm: `OK`

Phase 11 therefore validated self-healing at both the infrastructure and application-service layers:

`Instance Failure / Application Failure -> ALB Health Detection -> Auto Scaling Replacement -> Bootstrap -> Target Registration -> Health Validation -> Traffic Restoration`
