# Phase 0.1A — Application Discovery

**Project:** ArtsPond Infrastructure & Security  
**Phase:** Phase 0 — Discovery & Foundation  
**Section:** 0.1A — Application Discovery  
**Status:** In Progress  
**Date:** September 2, 2026

---

## 1. Objective

The objective of this document is to establish a baseline understanding of the ArtsPond application ecosystem before making infrastructure, security, or configuration changes.

This discovery will document:

- Applications and platforms
- Application architecture
- Hosting components
- Databases
- Storage
- Authentication
- Payment integrations
- External services
- Environments
- Application dependencies
- Known gaps and items requiring verification

The information in this document will be classified as either:

- **Documented** — information obtained from existing ArtsPond documentation.
- **Verified** — information confirmed directly from the running environment.
- **Requires Verification** — information that has been documented but has not yet been independently confirmed.

---

## 2. Application Overview

ArtsPond currently operates a web-based platform built primarily on WordPress. The documented architecture consists of a main WordPress Multisite environment hosted on `pondMa` and a separate social/community WordPress installation hosted on `pondWe`.

The application architecture includes web servers, PHP application runtime, Redis caching, managed Azure database services, Azure Blob Storage, Cloudflare, and several external services.

### 2.1 Main Application — pondMa

The primary ArtsPond application is hosted on the Azure virtual machine identified as `pondMa`.

Documented configuration:

| Component | Technology | Purpose | Status |
|---|---|---|---|
| Operating System | Ubuntu 24.04 | Server operating system | Documented |
| Web Server | Nginx 1.24 | HTTP/HTTPS request handling | Documented |
| Application Runtime | PHP 8.2-FPM | Executes WordPress/PHP application code | Documented |
| CMS | WordPress Multisite | Main application platform | Documented |
| Object Cache | Redis | WordPress object caching | Documented |
| Database | Azure Database for MySQL | Application database | Documented |
| Media Storage | Azure Blob Storage | Persistent media/file storage | Documented |
| Monitoring/Analytics | Matomo | Web analytics | Documented |
| Administration | Webmin | Server administration | Documented |
| Private Connectivity | Tailscale | Private connectivity to infrastructure | Documented |

### 2.2 WordPress Multisite

The main WordPress installation is configured as a Multisite deployment.

The documented environment contains multiple sites and domain mappings within a single WordPress installation and database environment.

Documented sites include:

| Site | Function | Status |
|---|---|---|
| Main ArtsPond site | Primary platform | Documented |
| Opportunities | Opportunities | Documented |
| Spaces | Spaces | Documented |
| Journals | Journals | Documented |
| Events | Events | Documented |
| Learning | Learning | Documented |
| Contacts | Contacts | Documented |
| Mutual Aid | Mutual aid | Documented |
| togetherthere.ca | Project site | Documented |
| digitalaso.ca | Project site | Documented |
| hatchopen.com | Project site | Documented |
| ilostmygig.ca | Project site | Documented |

> **Note:** Existing documentation indicates 13 sites in total. The exact current site list will be verified against the running WordPress installation during infrastructure/application verification.

### 2.3 Social Platform — pondWe

A separate WordPress installation is hosted on the Azure VM identified as `pondWe`.

Documented configuration:

| Component | Technology | Status |
|---|---|---|
| Operating System | Ubuntu 22.04 | Documented |
| Web Server | Nginx | Documented |
| Application Runtime | PHP 8.2-FPM | Documented |
| CMS | WordPress | Documented |
| Social Platform | PeepSo | Documented |
| Object Cache | Redis | Documented |
| Database | Local MySQL | Documented |

The social platform is currently protected by an HTTP 503 "Coming Soon" response and is not considered part of the actively accessible public application surface.

The following items require verification:

- Whether `pondWe` is still required.
- Whether local MySQL is actively used.
- The relationship between `pondMa` and `pondWe`.
- The current SSO/OIDC implementation.
- Whether `pondWe` will be part of the future production architecture.

### 2.4 Application Request Processing

The documented request flow for the primary ArtsPond platform is:

```text
Internet User
      |
      v
Cloudflare
(DNS / CDN / WAF / DDoS / TLS)
      |
      v
pondMa
(Azure VM)
      |
      v
Nginx
      |
      +------------------+
      |                  |
      v                  v
FastCGI Cache        PHP 8.2-FPM
                           |
                           +------> Redis
                           |
                           +------> Azure Database for MySQL
                           |
                           +------> Azure Blob Storage
```

For anonymous requests, Nginx FastCGI caching can serve cached content without invoking PHP.

Requests involving authenticated users or dynamic functionality bypass the cache and are processed by PHP-FPM.

The documented architecture identifies PHP-FPM workers and database activity as important considerations for authenticated request capacity.

**Status:** Documented — infrastructure verification pending.

### 2.5 Application Services

The documented application ecosystem includes:

| Service | Purpose | Status |
|---|---|---|
| WordPress | Main CMS/application platform | Documented |
| WordPress Multisite | Multi-site architecture | Documented |
| PeepSo | Social/community functionality | Documented |
| Redis | Object caching | Documented |
| Matomo | Analytics | Documented |
| Webmin | Server administration | Documented |
| Nginx | Web server/reverse proxy | Documented |
| PHP-FPM | Application runtime | Documented |

---

## 3. Application Architecture & Data Flow

### 3.1 High-Level Architecture

The documented ArtsPond application architecture consists of two primary application servers hosted on Azure virtual machines.

The main application is hosted on `pondMa`, while the social/community application is hosted separately on `pondWe`.

Cloudflare provides the public-facing DNS, CDN, WAF, DDoS protection, and TLS termination layer.

The primary application data is stored in managed Azure services rather than on the application VM.

```text
                         INTERNET
                            |
                            v
                    +---------------+
                    |   Cloudflare   |
                    |               |
                    | DNS            |
                    | CDN            |
                    | WAF            |
                    | DDoS Protection|
                    | TLS            |
                    +-------+-------+
                            |
                  +---------+---------+
                  |                   |
                  v                   v
            +-----------+       +-----------+
            |  pondMa   |       |  pondWe   |
            | Azure VM  |       | Azure VM  |
            +-----+-----+       +-----+-----+
                  |                   |
                  |                   |
                  v                   v
             Nginx/PHP             Nginx/PHP
                  |                   |
                  v                   v
               Redis              Redis
                  |                   |
                  |              Local MySQL
                  |
          +-------+--------+
          |                |
          v                v
   Azure MySQL       Azure Blob Storage
   Database          Media Storage
```

**Status:** Documented — infrastructure verification pending.

### 3.2 Main Application Data Flow

The documented request flow for the primary ArtsPond platform is:

```text
User
 |
 v
Cloudflare
 |
 | HTTPS
 v
pondMa
 |
 v
Nginx
 |
 +-----------------------------+
 |                             |
 | Anonymous Request           | Dynamic/Auth Request
 |                             |
 v                             v
FastCGI Cache              PHP-FPM
                                |
                         +------+------+
                         |             |
                         v             v
                       Redis       Azure MySQL
                                      |
                                      |
                                      v
                                Application Data
```

For anonymous requests, cached responses may be served by Nginx without requiring PHP execution.

Requests involving authenticated users or dynamic functionality bypass the cache and are processed by PHP-FPM.

**Status:** Documented — verification pending.

### 3.3 Media Data Flow

Application media is documented as being stored in Azure Blob Storage.

The documented media delivery architecture is:

```text
WordPress
    |
    v
Azure Blob Storage
    |
    v
Cloudflare Worker
    |
    v
media.artspond.com
    |
    v
End User
```

This separates media storage from the application server and allows media delivery to be handled independently from the WordPress VM.

The following items require verification:

- Azure Storage Account name
- Blob container(s)
- Blob access level
- Blob versioning
- Blob soft delete
- Storage redundancy
- Cloudflare Worker configuration
- Relationship between the Worker and `media.artspond.com`

**Status:** Documented — verification pending.

### 3.4 Database Data Flow

The main WordPress application uses Azure Database for MySQL as its primary database service.

The documented Azure MySQL environment contains:

- WordPress application database
- Matomo database
- Additional databases associated with the ArtsPond environment

The documented architecture indicates that the application VMs do not host the primary application database.

```text
pondMa
  |
  | MySQL connection over network
  | TLS required
  v
Azure Database for MySQL
  |
  +--> WordPress database
  |
  +--> Matomo database
  |
  +--> Other application databases
```

The following items require verification:

- Azure MySQL server name
- Azure MySQL SKU/tier
- Azure region
- Network access configuration
- Private/public connectivity
- Firewall rules
- TLS configuration
- Backup/PITR configuration
- Database inventory

**Status:** Documented — verification pending.

### 3.5 Social Platform Data Flow

The social platform hosted on `pondWe` is documented as using local MySQL rather than Azure Database for MySQL.

```text
User
 |
 v
Cloudflare
 |
 v
pondWe
 |
 +--> Nginx
 |
 +--> PHP-FPM
 |
 +--> Redis
 |
 +--> Local MySQL
 |
 +--> PeepSo
```

The social platform currently returns an HTTP 503 "Coming Soon" response.

This architecture requires further investigation because the main application uses a managed Azure database while the social platform uses a local database.

**Status:** Documented — verification pending.

### 3.6 Authentication Flow

The existing documentation indicates that `pondMa` and `pondWe` are linked through SSO/OIDC.

The exact identity provider and implementation details have not yet been independently verified.

Expected flow:

```text
User
 |
 v
ArtsPond Application
 |
 v
Identity Provider
 |
 | Authentication
 v
OIDC / OAuth Tokens
 |
 v
ArtsPond Application
```

Items requiring verification:

- Identity provider
- Entra ID or other identity service
- Application registrations
- Client IDs
- Redirect URIs
- Client secrets/certificates
- Token configuration
- MFA requirements
- User provisioning
- Session management
- Logout behavior

**Status:** Requires Verification.

> **Security note:** Do not place passwords, API keys, client secrets, tokens, private keys, or other credentials in this document.

### 3.7 Payment Flow

The documented payment architecture references:

- Helcim
- Stripe Connect

The documented design indicates that payment processing is performed through hosted/tokenized payment services rather than storing raw card data within the ArtsPond application.

High-level flow:

```text
User
 |
 v
ArtsPond Application
 |
 v
Payment Provider
 |
 +--> Helcim
 |
 +--> Stripe Connect
 |
 v
Payment Result
 |
 v
ArtsPond Application
```

The following require verification:

- Which application uses each payment provider
- Current payment integrations
- API/webhook configuration
- Authentication mechanism
- Secret storage
- Payment-related data stored by ArtsPond
- Webhook endpoints
- Failure/retry behavior

**Status:** Requires Verification.

### 3.8 Backup and Infrastructure Connectivity

The documented infrastructure includes an on-premises Synology NAS used as a backup destination.

`pondMa` has Tailscale configured for private connectivity to the NAS.

```text
                    Azure
                      |
                  +---+---+
                  |pondMa |
                  +---+---+
                      |
                  Tailscale
                      |
                      v
                Synology NAS
                Backup Storage
```

The current documentation indicates that `pondWe` is not connected to Tailscale and therefore does not currently have the same private path to the NAS.

**Status:** Documented — verification pending.

### 3.9 Architecture Dependencies

The application depends on several external and internal components.

| Dependency | Used By | Criticality | Verification |
|---|---|---|---|
| Cloudflare | Public applications | High | Pending |
| Azure VM — pondMa | Main application | Critical | Pending |
| Azure VM — pondWe | Social platform | Medium | Pending |
| Azure Database for MySQL | Main application | Critical | Pending |
| Azure Blob Storage | Media | High | Pending |
| Cloudflare Worker | Media delivery | High | Pending |
| Redis | WordPress | High | Pending |
| Synology NAS | Backup | High | Pending |
| Tailscale | Private connectivity | Medium/High | Pending |
| Identity Provider | Authentication | High | Pending |
| Helcim | Payments | High | Pending |
| Stripe Connect | Payments | High | Pending |
| Matomo | Analytics | Medium | Pending |
| Webmin | Administration | Medium | Pending |

### 3.10 Initial Architecture Observations

#### Observation 1 — Managed database architecture

The primary application database is hosted on Azure Database for MySQL rather than directly on the application VM.

**Assessment:** Positive architectural pattern.

---

#### Observation 2 — Externalized media storage

Application media is stored in Azure Blob Storage rather than relying entirely on local VM disk.

**Assessment:** Positive architectural pattern, subject to verification of access controls, redundancy, versioning, and recovery capabilities.

---

#### Observation 3 — Separate application servers

The main and social platforms are hosted on separate VMs.

**Assessment:** Provides some workload separation, but introduces additional infrastructure and operational complexity.

---

#### Observation 4 — Local database dependency on pondWe

The social platform currently uses local MySQL on `pondWe`.

**Assessment:** Requires investigation because local database storage creates a different availability, backup, recovery, and scaling model from the primary application.

---

#### Observation 5 — No staging environment documented

A dedicated staging environment has not been identified in the current documentation.

**Assessment:** Important operational and security gap requiring further investigation.

---

#### Observation 6 — Backup connectivity

`pondMa` has a private Tailscale path to the Synology NAS.

**Assessment:** Useful for backup connectivity, but the security and failure implications of server-initiated backup operations require further assessment during the Backup and Disaster Recovery phase.

---

## 4. Environment Model

### 4.1 Purpose

The environment model identifies the environments used to develop, test, stage, and operate the ArtsPond platform.

A clear separation between environments is important for:

- Safe application changes
- Security testing
- Infrastructure testing
- Patch validation
- Deployment control
- Disaster recovery
- CI/CD implementation
- Reducing the risk of production outages

The current environment model is based on the existing documentation and has not yet been fully verified against the running infrastructure.

### 4.2 Current Environment Inventory

| Environment | Current Status | Known Infrastructure | Purpose | Verification |
|---|---|---|---|---|
| Production | Exists | pondMa / pondWe | Live application infrastructure | Pending |
| Development | Unknown | Not identified | Application development | Required |
| Test | Unknown | Not identified | Functional/security testing | Required |
| Staging | Not currently available | Not identified | Production-like validation | Required |
| Disaster Recovery | Not identified | Synology / Azure backups | Recovery operations | Required |

### 4.3 Production Environment

The current documented production/live estate consists primarily of:

- `pondMa` — main ArtsPond WordPress Multisite platform
- `pondWe` — separate social/community WordPress platform
- Azure Database for MySQL
- Azure Blob Storage
- Cloudflare
- Cloudflare Worker
- Redis
- Synology NAS backup infrastructure

The production environment currently contains the primary application components and associated infrastructure.

**Status:** Documented — Azure infrastructure verification pending.

### 4.4 Development Environment

A dedicated development environment has not been clearly identified in the available documentation.

The following questions require verification:

- Does a dedicated development Azure environment exist?
- Is development performed locally?
- Does the development environment use a separate database?
- Does development use separate Blob Storage?
- Are development credentials isolated from production?
- Is development connected to production services?
- How are application changes transferred to production?

**Status:** Requires Verification.

### 4.5 Test Environment

A dedicated test environment has not been clearly identified.

Items requiring verification:

- Whether a test environment exists.
- Whether automated testing is used.
- Whether security testing is performed against a non-production system.
- Whether test data is isolated from production data.
- Whether test environments use separate credentials.
- Whether test environments can access production resources.

**Status:** Requires Verification.

### 4.6 Staging Environment

A dedicated staging environment has not been identified in the current documentation.

This is considered an important operational gap.

A staging environment should eventually provide a production-like environment where changes can be validated before being deployed to production.

Potential staging components could include:

```text
                    STAGING
                       |
              +--------+--------+
              |                 |
           Staging VM      Staging Database
              |                 |
           WordPress        MySQL
              |
        Staging Blob Storage
```

The staging environment should be isolated from production while remaining sufficiently similar to production to provide meaningful deployment and security testing.

Potential staging activities include:

- OS patch testing
- PHP version testing
- WordPress updates
- Plugin updates
- Configuration changes
- Security configuration testing
- Bicep deployment testing
- Backup/restore testing
- Performance testing
- Application deployment validation

**Status:** Not currently identified — requires verification.

### 4.7 Disaster Recovery Environment

A dedicated disaster recovery environment has not been identified.

The current documented recovery architecture relies primarily on:

- Azure Database backups/PITR
- Azure/database backup copies
- Synology NAS backups
- VM/application file backups
- Server configuration backups
- Azure Blob Storage durability

The existence of backups does not automatically mean that a complete disaster recovery environment exists.

A future DR design should address:

- Recovery location
- Recovery procedures
- Recovery time objective (RTO)
- Recovery point objective (RPO)
- Infrastructure redeployment
- Database restoration
- Blob/media restoration
- DNS/Cloudflare recovery
- Secrets recovery
- Application configuration recovery
- Validation after restoration

**Status:** Requires Verification.

### 4.8 Environment Separation

The current documentation indicates that a clear staging environment and CI/CD process are not currently available.

This creates a potential operational risk because changes may need to be tested directly against production infrastructure.

A future target architecture should aim for:

```text
Developer
    |
    v
Development
    |
    v
Test
    |
    v
Staging
    |
    | Approval
    v
Production
    |
    v
Disaster Recovery
```

The exact environment structure should be determined after the current infrastructure, application deployment process, and organizational requirements have been verified.

### 4.9 Environment Isolation Requirements

During the infrastructure discovery phase, the following isolation controls should be investigated:

| Control | Development | Test | Staging | Production |
|---|---|---|---|---|
| Separate VM | Unknown | Unknown | No/Unknown | Yes |
| Separate database | Unknown | Unknown | No/Unknown | Yes |
| Separate Blob Storage | Unknown | Unknown | No/Unknown | Yes |
| Separate credentials | Unknown | Unknown | Unknown | Required |
| Separate secrets | Unknown | Unknown | Unknown | Required |
| Network isolation | Unknown | Unknown | Unknown | Required |
| CI/CD deployment | Unknown | Unknown | No | No/Unknown |
| Production data access | Unknown | Unknown | Unknown | Yes |

> **Note:** "Unknown" means the configuration has not been verified. It does not necessarily mean the control is absent.

### 4.10 Environment Risks Identified During Documentation Review

#### Risk ENV-01 — No confirmed staging environment

A dedicated staging environment has not been identified.

**Potential impact:**

- Production changes may be difficult to validate safely.
- Security changes may require production testing.
- Infrastructure changes may introduce unexpected outages.
- Application updates may be difficult to roll back.

**Priority:** High

---

#### Risk ENV-02 — No confirmed CI/CD pipeline

No established CI/CD deployment process has been identified.

**Potential impact:**

- Manual deployments
- Configuration drift
- Inconsistent deployments
- Limited deployment auditability
- Increased human error

**Priority:** Medium/High

---

#### Risk ENV-03 — Environment boundaries are unclear

Development, testing, staging, and disaster recovery environments have not yet been fully identified.

**Potential impact:**

- Unclear separation of production and non-production workloads
- Potential credential reuse
- Difficulty testing infrastructure changes
- Difficulty establishing reliable deployment processes

**Priority:** High

---

### 4.11 Verification Plan

The environment model will be verified during the next discovery activities.

The following sources will be reviewed:

1. Azure subscriptions
2. Azure resource groups
3. Azure virtual machines
4. Azure networking
5. Azure Database for MySQL
6. Azure Storage Accounts
7. Cloudflare
8. Git repositories
9. Application deployment process
10. Existing development/test infrastructure

The final environment model will distinguish clearly between:

- **Confirmed**
- **Documented**
- **Unknown**
- **Recommended**

---

## 5. Next Step

The next activity is:

**Phase 0.1B — Azure Infrastructure Discovery**

The documented application architecture will be compared against the actual Azure environment.

The verification process will begin with:

1. Azure Subscription
2. Resource Groups
3. Virtual Machines
4. Networking
5. Azure Database for MySQL
6. Azure Storage Accounts
7. Identity and access
8. Backup and recovery resources
9. Monitoring resources

No production configuration changes should be made during this initial verification activity.


**Section:** 0.1B — Azure Infrastructure Discovery

## 6. Azure Infrastructure Verification

### 6.1 Azure Subscription

The ArtsPond Azure infrastructure was reviewed through the Azure Portal.

The resources identified during the initial verification are hosted under
the **Microsoft Azure Sponsorship** subscription.

| Attribute                  | Value                                                     | Verification Status |
| -------------------------- | --------------------------------------------------------- | ------------------- |
| Subscription Name          | Microsoft Azure Sponsorship                               | Verified            |
| Subscription ID            | Recorded separately; not included in public documentation | Verified            |
| Subscription Status        | Active / resource access confirmed                        | Verified            |
| Azure Region(s)            | Canada Central and Canada East                            | Verified            |
| Resource Groups Identified | `apo27`, `apo28`                                          | Verified            |

> **Security Note:** The subscription ID was observed during the Azure
> Portal review but is intentionally not included in public GitHub
> documentation. Credentials, secrets, SSH private keys, API keys,
> client secrets, storage keys, and passwords must never be stored in
> this document.

---

### 6.2 Resource Group Inventory

Two ArtsPond-related resource groups were identified during the Azure
infrastructure review.

| Resource Group | Primary Workload                            | Region(s)                    | Verification Status |
| -------------- | ------------------------------------------- | ---------------------------- | ------------------- |
| `apo27`        | Main application infrastructure             | Canada Central / Canada East | Verified            |
| `apo28`        | Social/community application infrastructure | Canada Central               | Verified            |

The naming convention suggests that `apo27` and `apo28` represent
separate application infrastructure groupings.

The relationship between these resource groups and the logical
environments (production, development, test, staging, or DR) requires
further verification.

---

## 6.3 Resource Group `apo27`

Resource group `apo27` contains the primary documented application
infrastructure identified during the Azure review.

### 6.3.1 Asset Inventory

| Asset Type             | Resource Name                | Key Details                                      | Status   |
| ---------------------- | ---------------------------- | ------------------------------------------------ | -------- |
| Virtual Machine        | `apo27VM`                    | Ubuntu 24.04, Standard D2s v5, 2 vCPU, 8 GiB RAM | Verified |
| Public IP              | `apo27VM-ip`                 | Static Standard Public IP                        | Verified |
| Network Interface      | `apo27vm65_z1`               | Private IP `172.17.0.4`                          | Verified |
| Network Security Group | `apo27VM-nsg`                | 4 inbound rules, 2 outbound rules                | Verified |
| OS Disk                | `apo27VM_OsDisk`             | Premium SSD LRS, 64 GiB                          | Verified |
| SSH Key Resource       | `apo27VM_key`                | RSA SSH key resource                             | Verified |
| Virtual Network        | `vnet-canadacentral`         | `172.17.0.0/16`                                  | Verified |
| MySQL Flexible Server  | `apo27Ssql`                  | MySQL 8.0, B1ms, 1 vCore, 2 GiB                  | Verified |
| Storage Account        | `apo27stg`                   | StorageV2, Standard LRS                          | Verified |
| Snapshot               | `apo-Snap`                   | VM snapshot                                      | Verified |
| Action Group           | `RecommendedAlertRules-AG-1` | Alert notifications                              | Verified |
| Metric Alerts          | Multiple                     | CPU, memory, disk, network, availability         | Verified |

---

### 6.3.2 Main Virtual Machine — `apo27VM`

The Azure resource currently identified as `apo27VM` is an Ubuntu Linux
virtual machine located in Canada Central, Availability Zone 1.

| Property         | Value                                 | Status                |
| ---------------- | ------------------------------------- | --------------------- |
| Resource Group   | `apo27`                               | Verified              |
| Location         | Canada Central — Zone 1               | Verified              |
| Operating System | Ubuntu Linux 24.04                    | Verified              |
| VM Size          | Standard D2s v5                       | Verified              |
| vCPUs            | 2                                     | Verified              |
| Memory           | 8 GiB                                 | Verified              |
| Architecture     | x64                                   | Verified              |
| VM Generation    | V2                                    | Verified              |
| VNet             | `vnet-canadacentral`                  | Verified              |
| Subnet           | `snet-canadacentral-1`                | Verified              |
| Private IP       | `172.17.0.4`                          | Verified              |
| Public IP        | Static public IP associated           | Verified              |
| OS Disk          | `apo27VM_OsDisk`                      | Verified              |
| Data Disks       | None                                  | Verified              |
| Azure Agent      | Ready                                 | Verified              |
| Image Publisher  | Canonical                             | Verified              |
| Image            | Ubuntu 24.04 LTS                      | Verified              |
| Security Type    | Not explicitly recorded in VM summary | Requires Verification |
| Admin Username   | `apo27VMAdmin`                        | Verified              |

> **Security Note:** The administrator username is documented here for
> infrastructure inventory purposes. Authentication credentials and
> private SSH keys must not be stored in this document.

---

### 6.3.3 Main VM Public IP

The VM has a static public IP resource.

| Property           | Value                   | Status   |
| ------------------ | ----------------------- | -------- |
| Resource           | `apo27VM-ip`            | Verified |
| Location           | Canada Central — Zone 1 | Verified |
| SKU                | Standard                | Verified |
| Allocation         | Static                  | Verified |
| Associated NIC     | `apo27vm65_z1`          | Verified |
| Associated VM      | `apo27VM`               | Verified |
| Routing Preference | Microsoft Network       | Verified |

The existence of a public IP does not by itself establish whether the
VM is directly accessible from the Internet. Effective accessibility
depends on the NSG, guest firewall, routing, and application-level
controls.

**Next verification:** Review the effective inbound NSG rules and
confirm whether traffic is restricted to Cloudflare, administrative
sources, or other approved networks.

---

### 6.3.4 Network Interface — `apo27vm65_z1`

| Property                   | Value                  | Status   |
| -------------------------- | ---------------------- | -------- |
| VNet                       | `vnet-canadacentral`   | Verified |
| Subnet                     | `snet-canadacentral-1` | Verified |
| Private IP                 | `172.17.0.4`           | Verified |
| Public IP                  | `apo27VM-ip`           | Verified |
| Attached VM                | `apo27VM`              | Verified |
| NSG                        | `apo27VM-nsg`          | Verified |
| Accelerated Networking     | Enabled                | Verified |
| IP Forwarding              | Disabled               | Verified |
| Private IP Allocation      | Dynamic                | Verified |
| Public IP Allocation       | Static                 | Verified |
| Network Encryption Support | Not enabled            | Verified |

---

### 6.3.5 Virtual Network — `vnet-canadacentral`

| Property             | Value                  | Status   |
| -------------------- | ---------------------- | -------- |
| Resource Group       | `apo27`                | Verified |
| Location             | Canada Central         | Verified |
| Address Space        | `172.17.0.0/16`        | Verified |
| Subnet               | `snet-canadacentral-1` | Verified |
| Subnet Address Range | `172.17.0.0/24`        | Verified |
| DNS                  | Azure-provided DNS     | Verified |

Only one subnet was identified in the current inventory.

**Next verification:**

* NSG association
* Route tables
* NAT Gateway
* Azure Firewall
* VNet peering
* Private endpoints
* Service endpoints
* Effective routes

---

### 6.3.6 Network Security Group — `apo27VM-nsg`

The NSG is associated with the main VM's network interface.

| Property           | Value          | Status   |
| ------------------ | -------------- | -------- |
| Resource Group     | `apo27`        | Verified |
| Location           | Canada Central | Verified |
| Inbound Rules      | 4              | Verified |
| Outbound Rules     | 2              | Verified |
| Associated NICs    | 1              | Verified |
| Associated Subnets | 0              | Verified |

The current inventory does not yet contain the individual NSG rules.

**Next verification:** Record every inbound and outbound security rule,
including:

* Priority
* Source
* Source port
* Destination
* Destination port
* Protocol
* Action
* Description

This will be important for the Phase 1 security review.

---

### 6.3.7 OS Disk — `apo27VM_OsDisk`

| Property           | Value                | Status   |
| ------------------ | -------------------- | -------- |
| Size               | 64 GiB               | Verified |
| Storage Type       | Premium SSD LRS      | Verified |
| Disk Tier          | P6                   | Verified |
| IOPS               | 240                  | Verified |
| Throughput         | 50 MB/s              | Verified |
| Managed By         | `apo27VM`            | Verified |
| Availability Zone  | 1                    | Verified |
| Security Type      | Trusted Launch       | Verified |
| Encryption         | Platform-managed key | Verified |
| Provisioning State | Succeeded            | Verified |
| Data Disks         | None                 | Verified |

No data disk is currently attached to `apo27VM`.

---

## 6.4 Azure Database for MySQL — `apo27Ssql`

An Azure Database for MySQL Flexible Server was identified in resource
group `apo27`.

| Property               | Value           | Status   |
| ---------------------- | --------------- | -------- |
| Resource Group         | `apo27`         | Verified |
| Status                 | Ready           | Verified |
| Location               | Canada East     | Verified |
| MySQL Version          | 8.0             | Verified |
| Pricing Tier           | Burstable       | Verified |
| Compute Size           | Standard_B1ms   | Verified |
| vCores                 | 1               | Verified |
| Memory                 | 2 GiB           | Verified |
| Storage                | 32 GiB          | Verified |
| IOPS                   | Auto-scale      | Verified |
| Storage Autogrow       | Enabled         | Verified |
| Backup Retention       | 7 days          | Verified |
| Earliest Restore Point | August 17, 2026 | Verified |
| Maintenance            | System-managed  | Verified |
| Connectivity           | Public Access   | Verified |
| VNet Integration       | Not configured  | Verified |
| High Availability      | Disabled        | Verified |
| Replication            | None            | Verified |

### Initial observation

The main application VM is located in **Canada Central**, while the
Azure Database for MySQL server is located in **Canada East**.

This is not automatically a problem, but the cross-region placement
should be understood and documented because it may affect:

* Network latency
* Application performance
* Availability architecture
* Data residency considerations
* Disaster recovery planning
* Network security design

**Status:** Observation — requires further assessment.

The actual database names, database users, firewall rules, connectivity
model, and application-to-database configuration still require
verification.

---

## 6.5 Storage Account — `apo27stg`

The primary ArtsPond storage account identified in `apo27` is
`apo27stg`.

| Property                 | Value            | Status   |
| ------------------------ | ---------------- | -------- |
| Resource Group           | `apo27`          | Verified |
| Location                 | Canada Central   | Verified |
| Account Type             | StorageV2        | Verified |
| Performance              | Standard         | Verified |
| Replication              | LRS              | Verified |
| Access Tier              | Hot              | Verified |
| Created                  | December 3, 2025 | Verified |
| Blob Anonymous Access    | Enabled          | Verified |
| Blob Soft Delete         | Enabled — 7 days | Verified |
| Container Soft Delete    | Enabled — 7 days | Verified |
| Versioning               | Disabled         | Verified |
| Change Feed              | Disabled         | Verified |
| Public Network Access    | Enabled          | Verified |
| Minimum/Configured TLS   | 1.2              | Verified |
| Secure Transfer Required | Enabled          | Verified |
| Storage Key Access       | Enabled          | Verified |
| Private Endpoints        | 0                | Verified |

### Initial observations

Several configuration characteristics require further security review:

1. Blob anonymous access is enabled.
2. Public network access is enabled.
3. Storage account key access is enabled.
4. Blob versioning is disabled.
5. No private endpoint is currently configured.
6. Blob and container soft delete are enabled for 7 days.

These are **observations, not yet final security findings**.

They should be assessed against the actual application requirements,
Cloudflare media architecture, backup strategy, and ArtsPond security
policy before any configuration changes are proposed.

---

## 6.6 Resource Group `apo28`

Resource group `apo28` contains the infrastructure associated with the
documented social/community platform.

### 6.6.1 Asset Inventory

| Asset Type             | Resource Name         | Key Details                                    | Status   |
| ---------------------- | --------------------- | ---------------------------------------------- | -------- |
| Virtual Machine        | `vm-pondwe`           | Ubuntu 22.04, Standard B2ms, 2 vCPU, 8 GiB RAM | Verified |
| Network Interface      | `nic-pondwe`          | Private IP `10.20.1.4`                         | Verified |
| Network Security Group | `nsg-pondwe`          | 3 inbound rules                                | Verified |
| OS Disk                | `osdisk-pondwe`       | Standard SSD LRS, 30 GiB                       | Verified |
| Public IP              | `pip-pondwe`          | Static Standard Public IP                      | Verified |
| Storage Account        | `pondwepixybkruojuww` | StorageV2, Standard LRS                        | Verified |
| Virtual Network        | `vnet-pondwe`         | `10.20.0.0/16`                                 | Verified |

---

## 6.7 Social VM — `vm-pondwe`

The Azure resource `vm-pondwe` corresponds to the documented social
application host.

| Property          | Value                       | Status   |
| ----------------- | --------------------------- | -------- |
| Resource Group    | `apo28`                     | Verified |
| Status            | Running                     | Verified |
| Location          | Canada Central              | Verified |
| Operating System  | Ubuntu Linux 22.04          | Verified |
| VM Size           | Standard B2ms               | Verified |
| vCPUs             | 2                           | Verified |
| Memory            | 8 GiB                       | Verified |
| Computer Name     | `pondwe`                    | Verified |
| VNet              | `vnet-pondwe`               | Verified |
| Subnet            | `snet-app`                  | Verified |
| Private IP        | `10.20.1.4`                 | Verified |
| Public IP         | Static public IP associated | Verified |
| VM Generation     | V2                          | Verified |
| Architecture      | x64                         | Verified |
| Azure Agent       | Ready                       | Verified |
| Health Monitoring | Disabled                    | Verified |
| Data Disks        | None                        | Verified |
| Auto Shutdown     | Disabled                    | Verified |
| Creation Date     | July 4, 2026                | Verified |
| Security Type     | Standard                    | Verified |

---

## 6.8 Social VM Network

### Network Interface — `nic-pondwe`

| Property               | Value          | Status   |
| ---------------------- | -------------- | -------- |
| Attached VM            | `vm-pondwe`    | Verified |
| VNet                   | `vnet-pondwe`  | Verified |
| Subnet                 | `snet-app`     | Verified |
| Private IP             | `10.20.1.4`    | Verified |
| Public IP              | `20.48.252.36` | Verified |
| NSG                    | `nsg-pondwe`   | Verified |
| Accelerated Networking | Disabled       | Verified |
| IP Forwarding          | Disabled       | Verified |
| Private IP Allocation  | Dynamic        | Verified |
| Public IP Allocation   | Static         | Verified |

### Network Security Group — `nsg-pondwe`

| Property          | Value          | Status   |
| ----------------- | -------------- | -------- |
| Resource Group    | `apo28`        | Verified |
| Location          | Canada Central | Verified |
| Inbound Rules     | 3              | Verified |
| Outbound Rules    | 0              | Verified |
| Associated Subnet | `snet-app`     | Verified |
| Associated NICs   | 0              | Verified |

The individual NSG rules still require verification.

---

## 6.9 Social VM OS Disk — `osdisk-pondwe`

| Property           | Value                | Status   |
| ------------------ | -------------------- | -------- |
| Size               | 30 GiB               | Verified |
| Storage Type       | Standard SSD LRS     | Verified |
| IOPS               | 500                  | Verified |
| Throughput         | 100 MB/s             | Verified |
| Managed By         | `vm-pondwe`          | Verified |
| OS                 | Linux                | Verified |
| VM Generation      | V2                   | Verified |
| Architecture       | x64                  | Verified |
| Security Type      | Standard             | Verified |
| Encryption         | Platform-managed key | Verified |
| Provisioning State | Succeeded            | Verified |

No data disk is currently attached to `vm-pondwe`.

---

## 6.10 Social Storage Account — `pondwepixybkruojuww`

| Property                   | Value          | Status   |
| -------------------------- | -------------- | -------- |
| Resource Group             | `apo28`        | Verified |
| Location                   | Canada Central | Verified |
| Account Type               | StorageV2      | Verified |
| Performance                | Standard       | Verified |
| Replication                | LRS            | Verified |
| Access Tier                | Hot            | Verified |
| Created                    | July 3, 2026   | Verified |
| Blob Anonymous Access      | Enabled        | Verified |
| Blob Soft Delete           | Disabled       | Verified |
| Container Soft Delete      | Disabled       | Verified |
| Versioning                 | Disabled       | Verified |
| Public Network Access      | Enabled        | Verified |
| TLS                        | 1.2            | Verified |
| Secure Transfer Required   | Enabled        | Verified |
| Storage Account Key Access | Enabled        | Verified |
| Private Endpoints          | 0              | Verified |

### Initial observation

The social platform's storage account currently has fewer data-protection
controls than `apo27stg`.

Specifically:

* Blob soft delete is disabled.
* Container soft delete is disabled.
* Versioning is disabled.
* Public network access is enabled.
* Anonymous blob access is enabled.
* Account key access is enabled.
* No private endpoint is configured.

These differences will be investigated during the security and backup
phases.

No changes should be made during the discovery phase.

---

## 6.11 Social Virtual Network — `vnet-pondwe`

| Property             | Value          | Status   |
| -------------------- | -------------- | -------- |
| Resource Group       | `apo28`        | Verified |
| Location             | Canada Central | Verified |
| Address Space        | `10.20.0.0/16` | Verified |
| Subnet Count         | 1              | Verified |
| Subnet               | `snet-app`     | Verified |
| Subnet Address Range | `10.20.1.0/24` | Verified |
| Connected Devices    | 1              | Verified |
| Encryption           | Disabled       | Verified |

---

## 6.12 Monitoring Resources

The `apo27` resource group contains an Azure Monitor Action Group and
multiple metric alert rules.

Documented alert categories include:

* Available memory
* Available bytes
* Data disk IOPS consumed percentage
* Network in
* Network out
* OS disk consumed percentage
* Percentage CPU
* VM availability

The presence of alert rules confirms that monitoring/alerting resources
exist in Azure.

However, the following still require verification:

* Alert thresholds
* Alert severity
* Alert destinations
* Notification recipients
* Whether alerts are actively firing
* Whether alerts cover all critical resources
* Whether application-level monitoring exists
* Whether logs are retained
* Whether a centralized Log Analytics workspace exists

**Status:** Partially Verified.

---

## 6.13 Snapshot

A VM snapshot named `apo-Snap` was identified in resource group `apo27`.

The snapshot is recorded as an existing Azure resource.

Further verification is required to determine:

* Snapshot creation date
* Snapshot source disk
* Snapshot purpose
* Snapshot retention
* Whether snapshots are automated
* Whether snapshots are part of the official backup strategy
* Whether the snapshot can actually support the documented recovery
  requirements

**Status:** Verified as existing; backup role requires verification.

---

## 6.14 Documentation-to-Azure Reconciliation

The initial Azure verification reveals that some existing documentation
and Azure resource names do not use the same naming convention.

| Documentation Reference | Azure Resource Identified         | Reconciliation Status                 |
| ----------------------- | --------------------------------- | ------------------------------------- |
| `pondMa`                | `apo27VM`                         | Requires confirmation                 |
| `pondWe`                | `vm-pondwe`                       | Confirmed/strong correlation          |
| Azure MySQL             | `apo27Ssql`                       | Confirmed                             |
| Azure Blob Storage      | `apo27stg`                        | Confirmed/usage requires verification |
| Social Blob Storage     | Not previously clearly documented | Newly identified                      |
| Main VNet               | `vnet-canadacentral`              | Confirmed                             |
| Social VNet             | `vnet-pondwe`                     | Confirmed                             |
| Main VM NSG             | `apo27VM-nsg`                     | Confirmed                             |
| Social VM NSG           | `nsg-pondwe`                      | Confirmed                             |

The `apo27VM` resource appears to correspond to the documented `pondMa`
host based on its Ubuntu 24.04 configuration and resource characteristics,
but the application-level hostname should be verified directly on the
VM before formally recording the mapping as confirmed.

---

## 6.15 Initial Azure Discovery Findings

The initial Azure review has identified the following items for further
investigation.

### AZ-OBS-01 — Main VM has a public IP

`apo27VM` has a static public IP.

**Status:** Observation

The effective Internet exposure must be determined by reviewing the NSG,
guest firewall, routing, and Cloudflare origin restrictions.

---

### AZ-OBS-02 — MySQL is publicly accessible

The Azure MySQL Flexible Server is configured for public access and does
not currently have VNet integration configured.

**Status:** Observation

The actual firewall configuration and permitted source ranges must be
reviewed before determining the security risk.

---

### AZ-OBS-03 — Main database is in a different Azure region

The main VM is in Canada Central while the Azure MySQL server is in
Canada East.

**Status:** Observation

Latency, data residency, availability, and architecture implications
require further assessment.

---

### AZ-OBS-04 — Main storage account has public/anonymous access enabled

`apo27stg` has anonymous blob access and public network access enabled.

**Status:** Observation

The actual containers and application access model must be inspected
before determining whether this configuration is required.

---

### AZ-OBS-05 — Social storage has fewer protection controls

The social storage account has blob soft delete and container soft delete
disabled, as well as versioning disabled.

**Status:** Observation

This should be compared with the application's backup and recovery
requirements.

---

### AZ-OBS-06 — Monitoring resources exist

Azure metric alerts and an Action Group are present in `apo27`.

**Status:** Partially Verified

Alert configuration and notification effectiveness require further
verification.

---

### AZ-OBS-07 — Environment separation is not yet established

The two resource groups appear to represent different application
workloads, but they have not yet been mapped definitively to
Production, Development, Test, or Staging environments.

**Status:** Requires Verification.

---

## 6.16 Next Verification Activities

The next Azure discovery activities will focus on:

1. Reviewing the individual NSG rules for `apo27VM-nsg`.
2. Reviewing the individual NSG rules for `nsg-pondwe`.
3. Reviewing Azure MySQL firewall/network access.
4. Reviewing the Azure Storage containers and access configuration.
5. Identifying Azure Backup resources.
6. Identifying Log Analytics workspaces.
7. Identifying Azure Monitor configuration.
8. Reviewing VM networking and effective routes.
9. Confirming the `pondMa` ↔ `apo27VM` relationship.
10. Determining whether any development, test, or staging resources exist.

**No infrastructure changes will be made during these verification
activities.**

### 6.17 apo27VM NSG — Inbound and Outbound Rules

The Azure Network Security Group `apo27VM-nsg` is associated with the
network interface of `apo27VM`.

#### Inbound rules

| Priority | Rule | Port | Protocol | Source | Action |
|---:|---|---:|---|---|---|
| 100 | AllowWebmin | 10000 | TCP | Any | Allow |
| 300 | SSH | 22 | TCP | Any | Allow |
| 320 | HTTP | 80 | TCP | Any | Allow |
| 340 | HTTPS | 443 | TCP | Any | Allow |
| 65000 | AllowVnetInBound | Any | Any | VirtualNetwork | Allow |
| 65001 | AllowAzureLoadBalancerInBound | Any | Any | AzureLoadBalancer | Allow |
| 65500 | DenyAllInBound | Any | Any | Any | Deny |

#### Outbound rules

| Priority | Rule | Port | Protocol | Source | Destination | Action |
|---:|---|---:|---|---|---|---|
| 100 | AllowMySQLOutbound | 3306 | TCP | Any | Any | Allow |
| 350 | pondstation | 51820 | UDP | Any | Any | Allow |
| 65000 | AllowVnetOutBound | Any | Any | VirtualNetwork | VirtualNetwork | Allow |
| 65001 | AllowInternetOutBound | Any | Any | Any | Internet | Allow |
| 65500 | DenyAllOutBound | Any | Any | Any | Any | Deny |

#### Initial observations

The NSG permits inbound TCP ports 22, 80, 443, and 10000 from
any source.

This differs from the documented security model, which indicates that
SSH and Webmin should be restricted to administrative access and that
the web origin should be protected behind Cloudflare.

These are discovery observations and are not yet classified as
confirmed vulnerabilities. Effective exposure must be verified against
the VM-level firewall (UFW), nginx access controls, SSH configuration,
and Cloudflare origin protection.

The outbound TCP/3306 rule is consistent with the VM requiring
connectivity to MySQL, but its destination scope is currently broad
(`Any`) and should be assessed during the security review.

The UDP/51820 rule is consistent with the documented use of Tailscale
and should be verified against the actual Tailscale configuration.
