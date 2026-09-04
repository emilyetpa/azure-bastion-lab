# ArtsPond --- 0.1 Application Discovery

**Phase:** 0 --- Discovery / Foundation\
**Activity:** 0.1 --- Application Discovery\
**Status:** In Progress\
**Purpose:** Establish an evidence-based understanding of the current
ArtsPond application, infrastructure, dependencies, access model,
security controls, and operational gaps before production changes are
made.

------------------------------------------------------------------------

## 1. Discovery Approach

The discovery process follows:

> **Observe → Document → Verify → Assess → Recommend**

The objective is to understand the current environment before making
changes.

During discovery:

-   Production configuration should not be changed unless explicitly
    approved.
-   Documentation should be compared with the running Azure environment.
-   Potential security issues should initially be recorded as
    observations, not automatically classified as vulnerabilities.
-   Effective behavior should be verified across multiple control layers
    before remediation is recommended.

------------------------------------------------------------------------

# 2. Application Overview

## 2.1 Main Application

  Component                Current State
  ------------------------ -----------------------------------------
  Application platform     WordPress
  Main application         WordPress Multisite
  Main host                Azure `apo27VM`; documented as `pondMa`
  Operating system         Ubuntu 24.04 LTS
  Web server               Nginx 1.24
  PHP                      PHP 8.2-FPM
  Object cache             Redis
  Main database            Azure Database for MySQL
  Media storage            Azure Blob Storage
  CDN / DNS / WAF / DDoS   Cloudflare
  TLS termination          Cloudflare
  Analytics                Matomo
  Server administration    Webmin
  Authentication           OIDC / SSO
  Payment services         Helcim + Stripe Connect
  Backup storage           Synology NAS
  Private connectivity     Tailscale

------------------------------------------------------------------------

## 2.2 WordPress Multisite

The main application is a WordPress Multisite installation hosted on
`apo27VM`.

The installation contains 13 sites:

-   Main ArtsPond site
-   `togetherthere.ca`
-   `digitalaso.ca`
-   `hatchopen.com`
-   `ilostmygig.ca`
-   Module sites:
    -   UP
    -   BE
    -   HI
    -   DO
    -   OK
    -   IN
    -   OH

The sites use a single WordPress installation and a shared database.

------------------------------------------------------------------------

## 2.3 Social Platform

The social platform is hosted separately on `vm-pondwe`.

  -----------------------------------------------------------------------
  Component                           Current State
  ----------------------------------- -----------------------------------
  Azure VM                            `vm-pondwe`

  Computer name                       `pondwe`

  Operating system                    Ubuntu 22.04

  Web server                          Nginx

  PHP                                 PHP 8.2-FPM

  Object cache                        Redis

  Application                         WordPress + PeepSo

  Database                            Local MySQL

  Current status                      HTTP 503 / Coming Soon

  Resource group                      `apo28`

  Region                              Canada Central

  Tailscale                           Not currently installed/connected
                                      according to existing documentation

  NAS access                          Not currently available from
                                      `pondWe` according to existing
                                      documentation
  -----------------------------------------------------------------------

The social platform is currently gated and is not serving normal public
application traffic.

Strategically, the social platform is expected to become a major growth
engine and should therefore be treated as a first-class workload in
future capacity, resilience, media/UGC, and security planning.

------------------------------------------------------------------------

# 3. Current Application Request Flow

The current main application request path is understood as:

``` text
                         INTERNET
                            |
                            v
                    +---------------+
                    |   Cloudflare   |
                    | DNS / CDN /    |
                    | WAF / DDoS /   |
                    | TLS termination|
                    +-------+-------+
                            |
                            v
                +-----------------------+
                |      apo27VM          |
                |      pondMa           |
                |                       |
                | Nginx                 |
                | PHP 8.2-FPM           |
                | Redis                 |
                | WordPress Multisite   |
                +-----+-----------+-----+
                      |           |
                      |           |
                      v           v
              Azure MySQL    Azure Blob
              Database       Storage
```

The social platform is separate:

``` text
                    +------------------+
                    |    vm-pondwe     |
                    |                  |
                    | Nginx            |
                    | PHP-FPM          |
                    | Redis            |
                    | WordPress        |
                    | PeepSo           |
                    | Local MySQL      |
                    +--------+---------+
                             ^
                             |
                         SSO / OIDC
                             |
                             v
                    apo27VM / pondMa
```

The main server also uses Tailscale for private connectivity toward the
Synology NAS.

------------------------------------------------------------------------

# 4. Detailed Main Application Request Flow

Based on the current configuration documentation:

``` text
Browser
   |
   v
Cloudflare Edge
   |
   | HTTP/HTTPS
   v
Nginx
   |
   +---- Anonymous request
   |        |
   |        +---- FastCGI cache HIT
   |               |
   |               +---- PHP may be bypassed
   |
   +---- Logged-in / dynamic request
            |
            v
        PHP 8.2-FPM
            |
            +---- Redis object cache
            |
            +---- Azure Database for MySQL
            |
            +---- Azure Blob Storage
            |
            +---- Wordfence WAF inside PHP
```

Documented cache bypass conditions include:

-   Logged-in cookies
-   `/wp-admin/`
-   `/wp-json/`
-   Cart
-   Checkout
-   My Account
-   `preview=true`

Cloudflare currently does not cache HTML broadly; anonymous requests may
be handled by nginx FastCGI caching at the origin.

------------------------------------------------------------------------

# 5. Current Main Server Baseline

The documented main server baseline includes:

  Component                        Current State
  -------------------------------- -----------------------------
  VM size                          Standard D2s v5
  CPU                              2 vCPU
  Memory                           8 GiB
  OS                               Ubuntu 24.04
  Nginx                            1.24
  PHP-FPM                          8.2
  PHP-FPM process model            Dynamic
  PHP `max_children`               30
  PHP `start_servers`              10
  Redis                            256 MB
  Redis eviction                   `allkeys-lru`
  UFW                              Default deny incoming
  Fail2ban                         SSH + WordPress login jails
  Tailscale                        Installed/active
  Webmin                           Active
  Local MySQL                      Present but vestigial
  Application DBs on local MySQL   None identified

The PHP-FPM configuration was selected around the available 8 GiB RAM
following right-sizing to D2s_v5.

------------------------------------------------------------------------

# 6. Environment Model

## 6.1 Current Environment

  Environment                Status
  -------------------------- ---------------------------
  Production / Live          Present
  Main application           `apo27VM`
  Social application         `vm-pondwe`
  Development                Not confirmed
  Test                       Not confirmed
  Staging                    Not present
  Dedicated DR environment   Not identified
  CI/CD                      Not currently implemented

The current environment model does not provide a dedicated staging
environment.

------------------------------------------------------------------------

## 6.2 Target Environment Direction

The desired operational model should progressively separate:

``` text
Development
     |
     v
Test
     |
     v
Staging
     |
     v
Production
```

Staging is currently the highest-value missing environment because it
would provide a controlled place to validate:

-   OS updates
-   WordPress updates
-   PHP updates
-   plugin updates
-   infrastructure changes
-   Bicep deployments
-   security configuration
-   backup/restore procedures

The recommended sequence is to establish staging before attempting broad
production automation.

------------------------------------------------------------------------

# 7. Business and Growth Context

ArtsPond is building toward an international platform serving artists,
organizations, participants, and the broader creative economy.

Current planning assumptions include:

-   Initial beta/pilot activity with approximately 100--200 test users
    within 3 months.
-   Approximately 3,000 users within 9 months.
-   Approximately 7,500 users within 12--18 months.
-   Longer-term potential for hundreds of thousands of users and
    potentially millions.
-   The pilot around September 2026 is expected to be invite-only.
-   Much of the estate is currently behind an HTTP 503 / "coming soon"
    gate.

A key scaling constraint is **authenticated members**, rather than raw
user count.

Anonymous pages can benefit from edge/origin caching, while
authenticated requests generate more PHP and database activity.

The social platform is expected to become a significant user-acquisition
and growth engine.

------------------------------------------------------------------------

# 8. Target Architecture Direction

The longer-term architecture direction favors:

-   Stateless and horizontally scalable application tiers.
-   Durable data in managed or portable services.
-   Disposable application servers.
-   Separate development, test, staging, and production environments.
-   Infrastructure as Code.
-   CI/CD.
-   Cloudflare for edge services and media delivery where economically
    appropriate.
-   Portability and avoidance of deep vendor lock-in.

The current VMs are not yet fully disposable because machine-local state
and hand configuration still exist.

The two main application VMs should currently be treated as "pets"
rather than fully immutable/disposable infrastructure.

Reverse-engineering the existing infrastructure into Bicep should
therefore follow:

> **Import/observe first → validate → codify → deploy safely**

rather than attempting to rebuild production immediately.

------------------------------------------------------------------------

# 9. External Services and Dependencies

  ---------------------------------------------------------------------------
  Service                 Function                    Current Status
  ----------------------- --------------------------- -----------------------
  Cloudflare              DNS / CDN / WAF / DDoS /    Confirmed
                          TLS                         

  Azure                   Primary infrastructure      Confirmed

  Azure Database for      Main application database   Confirmed
  MySQL                                               

  Azure Blob Storage      Media storage               Confirmed

  Cloudflare Worker       Media delivery path         Confirmed

  Helcim                  Payment processing          Confirmed /
                                                      implementation to
                                                      verify

  Stripe Connect          Payment processing          Confirmed /
                                                      implementation to
                                                      verify

  Synology NAS            Backup storage              Confirmed

  Tailscale               Private connectivity        Confirmed on main
                                                      server

  Matomo                  Analytics                   Confirmed

  Webmin                  Server administration       Confirmed

  PeepSo                  Social platform             Confirmed

  OIDC / SSO provider     Authentication/federation   Confirmed /
                                                      implementation to
                                                      verify

  GitHub                  Source control / repository Current status requires
                                                      verification
  ---------------------------------------------------------------------------

------------------------------------------------------------------------

# 10. Azure Infrastructure Inventory

## 10.1 Subscription

Azure resources reviewed are under:

**Microsoft Azure Sponsorship**

The subscription ID is intentionally not included in this document.

------------------------------------------------------------------------

# 11. Resource Group `apo27`

The `apo27` resource group contains the main application infrastructure.

## 11.1 Virtual Machine --- `apo27VM`

  Property                 Value
  ------------------------ -------------------------
  Resource name            `apo27VM`
  Resource group           `apo27`
  Region                   Canada Central
  Availability Zone        Zone 1
  OS                       Ubuntu 24.04 LTS
  VM size                  Standard D2s v5
  CPU                      2 vCPU
  Memory                   8 GiB
  Generation               V2
  Architecture             x64
  Security type            Trusted Launch
  Image publisher          Canonical
  Image                    Ubuntu 24.04 LTS Server
  Private IP               `172.17.0.4`
  Public IP                Present
  VNet                     `vnet-canadacentral`
  Subnet                   `snet-canadacentral-1`
  OS disk                  `apo27VM_OsDisk`
  Data disks               None
  Admin username           `apo27VMAdmin`
  Azure Agent              Ready
  Accelerated networking   Enabled

The VM currently has a public IP address.

------------------------------------------------------------------------

## 11.2 Public IP --- `apo27VM-ip`

  Property             Value
  -------------------- -------------------
  Public IP            `20.151.91.13`
  Allocation           Static
  SKU                  Standard
  Region               Canada Central
  Associated NIC       `apo27vm65_z1`
  Associated VM        `apo27VM`
  Routing preference   Microsoft Network

The public IP is currently attached to the main application VM.

------------------------------------------------------------------------

## 11.3 Network Interface --- `apo27vm65_z1`

  Property                     Value
  ---------------------------- ------------------------
  Private IP                   `172.17.0.4`
  Public IP                    `20.151.91.13`
  VNet                         `vnet-canadacentral`
  Subnet                       `snet-canadacentral-1`
  NSG                          `apo27VM-nsg`
  Accelerated networking       Enabled
  Network encryption support   No
  IP forwarding                Disabled
  Private IP allocation        Dynamic
  Public IP allocation         Static
  IP configurations            1

------------------------------------------------------------------------

## 11.4 OS Disk --- `apo27VM_OsDisk`

  Property            Value
  ------------------- ----------------------
  Size                64 GiB
  Storage type        Premium SSD LRS
  SKU                 P6
  IOPS                240
  Throughput          50 MB/s
  OS                  Linux
  Generation          V2
  Architecture        x64
  Availability Zone   1
  Security            Trusted Launch
  Encryption          Platform-managed key
  Provisioning        Succeeded

No data disks are attached.

------------------------------------------------------------------------

## 11.5 Snapshot

A VM snapshot named:

`apo-Snap`

is present.

Its purpose and recovery relevance should be verified during the Backup
and Disaster Recovery phase.

------------------------------------------------------------------------

# 12. Main VNet --- `vnet-canadacentral`

  Property               Value
  ---------------------- ------------------------
  Resource group         `apo27`
  Region                 Canada Central
  Address space          `172.17.0.0/16`
  Subnet                 `snet-canadacentral-1`
  Subnet address space   `172.17.0.0/24`
  DNS                    Azure Provided DNS

Topology:

``` text
vnet-canadacentral
└── snet-canadacentral-1
    └── apo27VM
        └── 172.17.0.4
```

------------------------------------------------------------------------

# 13. Main NSG --- `apo27VM-nsg`

The NSG is associated with the network interface of `apo27VM`.

## 13.1 NSG Associations

  Property             Value
  -------------------- ----------------
  Associated subnets   0
  Associated NICs      1
  NIC                  `apo27vm65_z1`

------------------------------------------------------------------------

## 13.2 Inbound Security Rules

  -------------------------------------------------------------------------------------------------------------------
      Priority Rule                                    Port Protocol   Source              Destination      Action
  ------------ ------------------------------- ------------ ---------- ------------------- ---------------- ---------
           100 AllowWebmin                            10000 TCP        Any                 Any              Allow

           300 SSH                                       22 TCP        Any                 Any              Allow

           320 HTTP                                      80 TCP        Any                 Any              Allow

           340 HTTPS                                    443 TCP        Any                 Any              Allow

         65000 AllowVnetInBound                         Any Any        VirtualNetwork      VirtualNetwork   Allow

         65001 AllowAzureLoadBalancerInBound            Any Any        AzureLoadBalancer   Any              Allow

         65500 DenyAllInBound                           Any Any        Any                 Any              Deny
  -------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------

## 13.3 Outbound Security Rules

  --------------------------------------------------------------------------------------------------------
      Priority Rule                            Port Protocol   Source           Destination      Action
  ------------ ----------------------- ------------ ---------- ---------------- ---------------- ---------
           100 AllowMySQLOutbound              3306 TCP        Any              Any              Allow

           350 pondstation                    51820 UDP        Any              Any              Allow

         65000 AllowVnetOutBound                Any Any        VirtualNetwork   VirtualNetwork   Allow

         65001 AllowInternetOutBound            Any Any        Any              Internet         Allow

         65500 DenyAllOutBound                  Any Any        Any              Any              Deny
  --------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------

## 13.4 Initial NSG Observations

The NSG currently permits inbound TCP ports:

-   22 --- SSH
-   80 --- HTTP
-   443 --- HTTPS
-   10000 --- Webmin

from `Any` source.

This differs from the documented security model, which indicates:

-   SSH should be restricted to administrative access.
-   Webmin should be restricted to administrative access.
-   Web traffic should be protected by Cloudflare origin controls.

These are discovery observations, not yet confirmed vulnerabilities.

Effective exposure must be verified against:

-   NSG effective security rules
-   UFW
-   nginx
-   SSH configuration
-   Webmin configuration
-   Cloudflare origin restrictions

The outbound TCP/3306 rule is consistent with MySQL connectivity but
currently has a broad destination scope.

UDP/51820 is consistent with WireGuard/Tailscale-related connectivity
and should be verified against the actual configuration.

------------------------------------------------------------------------

# 14. Azure Database for MySQL --- `apo27Ssql`

  Property                 Value
  ------------------------ ------------------------------------------
  Resource group           `apo27`
  Service                  Azure Database for MySQL Flexible Server
  Version                  MySQL 8.0
  Region                   Canada East
  Endpoint                 `apo27sql.mysql.database.azure.com`
  Administrator            `apo27sqlAdmin`
  Pricing tier             Burstable
  SKU                      Standard_B1ms
  vCores                   1
  Memory                   2 GiB
  Storage                  32 GiB
  IOPS                     Autoscale
  Storage autogrow         Enabled
  Backup retention         7 days
  Earliest restore point   2026-08-17
  Maintenance              System-managed
  High availability        Disabled
  Replication              None
  VNet integration         Not configured
  Network model            Public Access

The main application VM is in Canada Central while the MySQL server is
in Canada East.

This regional separation should later be assessed for:

-   latency
-   network security
-   cost
-   availability
-   data residency
-   future architecture

### 14.1 MySQL Firewall Rules — Verified

The Azure Portal firewall configuration for `apo27Ssql` shows three
explicit single-IP allow rules:

| Firewall rule | Start IP | End IP |
|---|---:|---:|
| `ClientIPAddress_2025-12-19_9-36-2` | `45.42.9.83` | `45.42.9.83` |
| `pondwe-vm` | `20.48.252.36` | `20.48.252.36` |
| `Allowvm` | `20.151.91.13` | `20.151.91.13` |

The IP `20.48.252.36` corresponds to the public IP of `vm-pondwe`.
The IP `20.151.91.13` corresponds to the public IP of `apo27VM`.
The purpose/owner of `45.42.9.83` remains unidentified and should be
verified before any change is considered.

The MySQL server remains configured for Public Access and does not use
VNet integration. The firewall rules materially restrict which public
source IPs can connect, but this should not be interpreted as proof that
all other database exposure has been eliminated.

------------------------------------------------------------------------

# 15. Azure Storage --- `apo27stg`

  Property                          Value
  --------------------------------- ----------------
  Resource group                    `apo27`
  Type                              StorageV2
  Performance                       Standard
  Redundancy                        LRS
  Region                            Canada Central
  Access tier                       Hot
  Created                           2025-12-03
  Blob anonymous access             Enabled
  Blob soft delete                  Enabled
  Blob soft delete retention        7 days
  Container soft delete             Enabled
  Container soft delete retention   7 days
  Blob versioning                   Disabled
  Change feed                       Disabled
  Public network access             Enabled
  Minimum TLS                       1.2
  Secure transfer required          Enabled
  Storage account key access        Enabled
  Private endpoints                 0

### 15.1 Verified Container Access Levels

The Azure Portal shows five containers in `apo27stg`:

| Container | Anonymous access level |
|---|---|
| `$logs` | Private |
| `pond-private` | Private |
| `wp-media-pondh` | Blob |
| `wp-media-pondp` | Blob |
| `wp-media-pondma` | Blob |

The three `wp-media-*` containers permit anonymous access at the Blob
level. This permits anonymous access to individual blobs where the blob
URL is known; it does not by itself mean that anonymous users can list
the container. No container is shown with the more permissive
`Container` anonymous access level.

When attempting to inspect `wp-media-pondma`, the Azure Portal reported
that the reviewer did not have permission to use the access key to list
data. The reviewer intentionally has read-only Azure access, so this is
an expected access limitation and is not itself a security finding. The
portal result showing zero listed items must not be interpreted as proof
that the container is empty.

### 15.2 Verified Storage Networking

`apo27stg` has **Public network access enabled from all networks**. No
network security perimeter is associated with the storage account, and
no private endpoints are configured.

This is a configuration observation, not a final vulnerability rating.
The current application architecture uses Azure Blob Storage for media,
and the documented media path includes `media.artspond.com` and a
Cloudflare Worker. The business/application dependency should be
validated before restricting network access.

### 15.3 Verified Storage Data Protection

The Recovery settings show:

-   Azure Backup for blobs: **Disabled**
-   Point-in-time restore for containers: **Disabled**
-   Blob soft delete: **Enabled, 7 days**
-   Container soft delete: **Enabled, 7 days**
-   Permanent delete for soft-deleted items: **Disabled**
-   Blob versioning: **Disabled**
-   Change feed: **Disabled**

The current configuration therefore provides a seven-day soft-delete
recovery window but does not provide the additional protection of Blob
Backup or container point-in-time restore. Adequacy should be assessed
against ArtsPond recovery objectives during Phase 3.

### 15.4 Verified Storage Configuration

Additional configuration checks confirm:

-   Secure transfer required: **Enabled**
-   Minimum TLS version: **1.2**
-   Allow Blob anonymous access: **Enabled**
-   Allow storage account key access: **Enabled**
-   Default to Microsoft Entra authorization in Azure portal: **Disabled**
-   SAS expiry interval limit: **Disabled**
-   Managed identity for SMB: **Disabled**

Storage-account key access may be required by the current WordPress media
integration. It should not be disabled without first verifying the
application authentication method and dependencies.

### 15.5 Storage RBAC — Partially Verified

At the storage account access-control view, the following inherited
assignments were visible:

| Principal | Role | Scope |
|---|---|---|
| ArtsPond CEO account | Owner | Subscription (Inherited) |
| Cedric Y. | Reader | Resource group (Inherited) |

The Azure Portal indicated four role assignments at the subscription
level, while two assignments were visible in the current results. A
complete subscription-level RBAC inventory therefore remains an open
discovery item.

### Initial observations

The storage account is publicly reachable at the network endpoint and
allows Blob anonymous access at the account level. Three WordPress media
containers use anonymous Blob access, while two containers are private.
These settings may be intentional for public media delivery and must be
assessed against the actual application/media path before remediation.

Versioning is disabled and should be assessed later as part of
backup/recovery and media protection.

------------------------------------------------------------------------

# 16. Azure Monitoring --- `apo27`

### 16.1 `apo27VM` Alert Rules — Verified

Azure Portal verification confirms **8 enabled metric-based alert rules**
for `apo27VM`. The alert inventory includes coverage for memory, disk
IOPS/consumption, inbound and outbound network traffic, CPU utilization,
and VM availability.

All visible alert rules use **Severity 3 — Informational**.

The CPU alert was opened and verified with the condition:

-   `Percentage CPU > 80`

The alert is associated with the Action Group:

-   `RecommendedAlertRules-AG-1`

The Action Group contains one email action directed to:

-   `hello@artspond.com`

A separate Azure Monitor alert view showed **0 fired alerts during the
previous 24 hours** at the time of discovery. This confirms the current
fired-alert state only; it does not prove that the alerting system has
been end-to-end tested.

### 16.2 `vm-pondwe` Monitoring — Verified Gap

Azure Portal verification shows:

-   Azure Monitor alert rules: **None configured**
-   Monitor page: **Alerts (Not configured)**
-   Current VM availability: **Available**
-   Azure outages: **No outages**
-   Health events: **No events**
-   VM extensions: **None found**

The absence of alert rules is a confirmed monitoring/notification gap
relative to `apo27VM`. The current healthy availability state should not
be interpreted as evidence of proactive monitoring.

### 16.3 Monitoring Assessment

The current Azure monitoring posture is asymmetric:

| Workload | Alert rules | Notification | Discovery status |
|---|---:|---|---|
| `apo27VM` | 8 enabled | `hello@artspond.com` | Verified |
| `vm-pondwe` | 0 | None identified | Verified gap |

The monitoring phase should further assess:

-   alert thresholds
-   alert severity
-   notification ownership
-   escalation
-   whether alerts are actionable
-   application-level monitoring
-   database monitoring
-   Cloudflare monitoring
-   logging and retention

------------------------------------------------------------------------

# 17. Resource Group `apo28`

The `apo28` resource group contains the social platform.

## 17.1 Virtual Machine --- `vm-pondwe`

  Property                 Value
  ------------------------ ----------------
  Resource name            `vm-pondwe`
  Computer name            `pondwe`
  Resource group           `apo28`
  Region                   Canada Central
  VM size                  Standard B2ms
  CPU                      2 vCPU
  Memory                   8 GiB
  OS                       Ubuntu 22.04
  Generation               V2
  Architecture             x64
  Private IP               `10.20.1.4`
  Public IP                `20.48.252.36`
  VNet                     `vnet-pondwe`
  Subnet                   `snet-app`
  NSG                      `nsg-pondwe` at subnet level
  Data disks               None
  Accelerated networking   Disabled
  Health monitoring        Disabled
  Auto shutdown            Disabled
  Creation date            2026-07-04

------------------------------------------------------------------------

## 17.2 Public IP --- `pip-pondwe`

  Property             Value
  -------------------- -------------------
  Public IP            `20.48.252.36`
  Allocation           Static
  SKU                  Standard
  Region               Canada Central
  Associated NIC       `nic-pondwe`
  Associated VM        `vm-pondwe`
  Routing preference   Microsoft Network

------------------------------------------------------------------------

## 17.3 Network Interface --- `nic-pondwe`

  Property                 Value
  ------------------------ ----------------
  Private IP               `10.20.1.4`
  Public IP                `20.48.252.36`
  VNet                     `vnet-pondwe`
  Subnet                   `snet-app`
  NSG                      None directly on NIC; subnet uses `nsg-pondwe`
  Accelerated networking   Disabled
  IP forwarding            Disabled
  Private IP allocation    Dynamic
  Public IP allocation     Static

------------------------------------------------------------------------

# 18. Social NSG --- `nsg-pondwe`

The NSG is associated with the subnet `snet-app` and is not directly
associated with the NIC. Therefore, the subnet-level NSG is the Azure
NSG control applicable to `vm-pondwe`.

### 18.1 Verified Custom Inbound Rules

| Priority | Rule | Port | Source | Action |
|---:|---|---:|---|---|
| 1000 | `Allow-SSH` | 22/TCP | `45.42.9.75/32` | Allow |
| 1010 | `Allow-HTTP` | 80/TCP | `0.0.0.0/0` | Allow |
| 1020 | `Allow-HTTPS` | 443/TCP | `0.0.0.0/0` | Allow |

Default inbound rules shown in the portal include:

-   `AllowVnetInBound` — priority 65000
-   `AllowAzureLoadBalancerInBound` — priority 65001
-   `DenyAllInBound` — priority 65500

### 18.2 Verified Custom Outbound Rules

No custom outbound rules were identified. The portal shows the standard
Azure outbound rules, including Internet outbound allowance and the
default deny rule at priority 65500.

### 18.3 Discovery Assessment

-   SSH is restricted at the Azure NSG to `45.42.9.75/32`.
-   HTTP and HTTPS are allowed from the Internet at the Azure NSG layer.
-   The VM has a static public IP `20.48.252.36`.
-   The NIC has no directly associated NSG; the subnet-level NSG provides
    the relevant Azure NSG control.

Effective security rules have not been independently captured yet.
Host-level controls such as UFW, nginx, fail2ban, and application
controls also remain unverified because the reviewer has intentionally
been granted read-only Azure access and cannot use Azure Run Command.

------------------------------------------------------------------------

# 19. Social OS Disk --- `osdisk-pondwe`

  Property        Value
  --------------- ----------------------
  Size            30 GiB
  Storage         Standard SSD LRS
  IOPS            500
  Throughput      100 MB/s
  OS              Linux
  Security type   Standard
  Encryption      Platform-managed key
  Provisioning    Succeeded

No data disks are attached.

------------------------------------------------------------------------

# 20. Social Storage --- `pondwepixybkruojuww`

  Property                     Value
  ---------------------------- ----------------
  Resource group               `apo28`
  Type                         StorageV2
  Performance                  Standard
  Redundancy                   LRS
  Region                       Canada Central
  Access tier                  Hot
  Blob anonymous access        Enabled
  Blob soft delete             Disabled
  Container soft delete        Disabled
  Blob versioning              Disabled
  Blob change feed             Disabled
  Public network access        Enabled from all networks
  Network security perimeter   None associated
  Minimum TLS                  1.2
  Secure transfer required     Enabled
  Storage account key access   Enabled
  Private endpoints            0
  Connectivity                 IPv4 only

### 20.1 Verified Container Access Levels

The Azure Portal shows two containers:

| Container | Anonymous access level |
|---|---|
| `pondwe-users` | Blob |
| `wp-media-pondwe` | Blob |

Both containers therefore permit anonymous access at the Blob level.
This does not by itself mean that users can list the containers.

The application purpose and data sensitivity of `pondwe-users` should be
verified before any recommendation to change its access level. The
`wp-media-pondwe` container may require public blob access for social
platform media delivery, but this dependency also requires verification.

The reviewer has intentionally been granted read-only Azure access.
Inability to list blob data through an access-key authentication method
is therefore an expected access limitation and is not itself a security
finding.

### 20.2 Verified Storage Networking

`pondwepixybkruojuww` has **Public network access enabled from all
networks**. No network security perimeter is associated and no private
endpoint is configured.

No network restriction should be inferred beyond what is visible in the
Azure configuration. Whether public network access is required should be
assessed against the social application's media and data flows.

### 20.3 Verified Storage Data Protection

The Azure Portal confirms that the following recovery/tracking controls
are disabled:

-   Azure Backup for blobs
-   Point-in-time restore for containers
-   Blob soft delete
-   Container soft delete
-   Permanent delete for soft-deleted items
-   Blob versioning
-   Blob change feed

The social storage account therefore has no native soft-delete or
version-history protection configured. This is an important recovery
gap to assess during Phase 3, particularly before user-generated content
becomes a significant workload.

### 20.4 Verified Storage Configuration

Additional configuration checks confirm:

-   Secure transfer required: **Enabled**
-   Minimum TLS version: **1.2**
-   Allow Blob anonymous access: **Enabled**
-   Allow storage account key access: **Enabled**
-   Default to Microsoft Entra authorization in Azure portal: **Disabled**
-   SAS expiry interval limit: **Disabled**
-   Managed identity for SMB: **Disabled**
-   Permitted scope for copy operations: **From any storage account**
-   Blob access tier: **Hot**
-   Connectivity: **IPv4 only**

Storage-account key access should not be disabled during discovery because
the current application authentication method has not yet been fully
verified.

### Initial observations

The social storage account has broad network reachability and both
containers use anonymous Blob access. These settings may be intentional
for the current/future social media delivery model, but the purpose and
data sensitivity of `pondwe-users` require verification.

The absence of soft delete, versioning, point-in-time restore, and Azure
Backup represents a recovery/protection gap for assessment in Phase 3.
No remediation should be performed during discovery.

# 21. Social VNet --- `vnet-pondwe`

  Property               Value
  ---------------------- ----------------
  Resource group         `apo28`
  Region                 Canada Central
  Address space          `10.20.0.0/16`
  Subnet                 `snet-app`
  Subnet address space   `10.20.1.0/24`
  Connected devices      1
  VNet encryption        Disabled

------------------------------------------------------------------------

# 22. VM-Level Security Controls Documented

Existing documentation indicates the main server has:

-   UFW with default-deny incoming policy.
-   HTTP/HTTPS permitted through controlled rules.
-   SSH key-only access.
-   Fail2ban for SSH and WordPress login protection.
-   Tailscale private connectivity.
-   Webmin access restricted through nginx/admin-IP controls.
-   Cloudflare origin protection.
-   TLS required for MySQL connectivity.

The intended model is:

``` text
Internet
   |
   v
Cloudflare
   |
   | Cloudflare ranges only
   v
apo27VM
   |
   +---- SSH ------> Admin IP
   |
   +---- Webmin ---> Admin IP
   |
   +---- Tailscale -> Private network
```

These controls have not yet been fully verified against the running VM.

------------------------------------------------------------------------

# 23. Current Access Status

The current discovery operator does **not currently have SSH access to
`apo27VM`**.

Therefore, the following cannot currently be directly verified from the
VM:

-   UFW configuration
-   SSH configuration
-   nginx configuration
-   Fail2ban configuration
-   Tailscale configuration
-   Webmin configuration
-   PHP-FPM configuration
-   Redis configuration
-   WordPress configuration
-   local MySQL status
-   backup scripts and schedules

No SSH access should be created or modified solely for this discovery
exercise.

Azure Portal-based discovery will continue first.

If server-level verification becomes necessary, it should be performed
by an authorized administrator or through an approved access mechanism.

------------------------------------------------------------------------

# 23.5 Resource-Group RBAC — Verified

The reviewer account is **Cedric Yetpa (`cedric@artspond.com`)**. The
account has intentionally restricted **Reader** access at the resource
group scope for both Azure resource groups.

### `apo27`

| Principal | Role | Scope |
|---|---|---|
| ArtsPond CEO account | Owner | Subscription (Inherited) |
| Cedric Yetpa | Reader | `apo27` resource group (This resource) |

### `apo28`

| Principal | Role | Scope |
|---|---|---|
| ArtsPond CEO account | Owner | Subscription (Inherited) |
| Cedric Yetpa | Reader | `apo28` resource group (This resource) |

The Reader assignments are consistent with the agreed discovery model:
observe and document without granting the reviewer production write or
execution permissions.

Subscription-wide RBAC cannot be treated as fully inventoried from the
reviewer's restricted access. A complete subscription-level access review
should therefore be supplied or performed by an authorized administrator
if required.

# 24. Existing Backup and Recovery State

Current documentation indicates:

  -----------------------------------------------------------------------
  Asset             Backup            Offsite           Status
  ----------------- ----------------- ----------------- -----------------
  Main DB           Azure PITR +      Yes               Documented
                    weekly NAS +                        
                    weekly local                        

  Main `/var/www`   Weekly rsync to   Yes               Documented
                    NAS                                 

  Main server       Weekly capture to Yes               Documented
  configuration     NAS                                 

  Social DB         Daily local dump  No                Gap

  Social            Weekly local      No                Gap
  uploads/config                                        

  Azure Blob media  Azure durability  Not fully         Needs
                                      verified          verification
  -----------------------------------------------------------------------

### `vm-pondwe` Azure Backup Verification

The Azure Backup + disaster recovery page for `vm-pondwe` displays an
Enhanced backup policy and a selected OS disk, but the reviewer received
a permissions error and could not perform the backup configuration
operation. A protected-item/last-backup status could not be independently
verified through the available Reader access.

Therefore, the current discovery record must not classify `vm-pondwe`
Azure Backup as either confirmed enabled or confirmed disabled. An
authorized administrator must verify active protection and restore history.

### Restore testing

A restore drill has **not yet been successfully performed**.

Therefore:

> Backup existence has been documented, but recoverability has not yet
> been proven.

This becomes a major item in Phase 3 --- Backup and Disaster Recovery.

------------------------------------------------------------------------

# 25. Backup Security Observation

The main server has access to the Synology NAS and performs
`rsync --delete`.

This creates a potential blast-radius concern:

``` text
apo27VM
   |
   | SSH key
   v
Synology NAS
   |
   +---- backups
```

If the main VM were compromised, its backup credentials and
`rsync --delete` capability could potentially be abused to damage backup
copies.

This should be assessed during the Backup/DR security review.

Potential future controls may include:

-   separate backup credentials
-   restricted backup-only accounts
-   immutable snapshots
-   retention controls
-   offline/offsite copies
-   one-way backup mechanisms
-   restricted delete permissions

No changes should be made during discovery.

------------------------------------------------------------------------

# 26. Local MySQL Technical Debt

The main VM reportedly has a local MySQL installation consuming
approximately 398 MB of RAM.

No application databases were identified on that local MySQL instance.

The application database is hosted in Azure Database for MySQL.

Therefore the local MySQL installation appears to be vestigial technical
debt.

**Potential future action:** verify dependencies and retire the unused
service after approval.

This should not be removed during discovery.

------------------------------------------------------------------------

# 27. Application and Infrastructure Scaling Direction

The current baseline is D2s_v5 for the main VM.

Scaling triggers should eventually include:

-   CPU utilization
-   PHP-FPM concurrency
-   request latency
-   database latency
-   Redis utilization
-   network throughput
-   authenticated member concurrency

The documented future scaling ladder is approximately:

``` text
Current VM
   |
   v
Right-size VM
   |
   v
Application Gateway / Load Balancing
   |
   v
VM Scale Set / horizontally scalable app tier
   |
   v
Larger/scaled managed database
   |
   v
Federated regional architecture
```

The goal is to avoid prematurely introducing complex infrastructure
before the workload requires it.

------------------------------------------------------------------------

# 28. Portability and Cloud Strategy

The Azure sponsorship grant is considered a runway rather than a
permanent architectural destination.

The target design should avoid unnecessary lock-in.

Key principles:

-   Keep compute portable.
-   Keep application servers as stateless as practical.
-   Keep durable data in managed or portable services.
-   Avoid dependencies that would require a complete rewrite to migrate.
-   Use Cloudflare/R2 where media storage and egress economics make it
    advantageous.
-   Maintain clear application/infrastructure boundaries.

The longer-term architecture anticipates regional editions/federation
and potentially an incremental migration from WordPress toward a
Python-based platform.

The current architecture should therefore preserve clear seams such as:

-   OIDC identity
-   REST interfaces
-   module boundaries
-   data/service boundaries

------------------------------------------------------------------------

# 29. Data Residency and Compliance Context

Current planning identifies several compliance and architectural
considerations.

## 29.1 PIPEDA

PIPEDA is the baseline privacy framework currently considered relevant
to the platform.

## 29.2 Quebec Law 25

If personal information is transferred outside Quebec, a Privacy Impact
Assessment may be required depending on the circumstances.

## 29.3 CASL

Electronic communications and marketing activities may be subject to
Canada's Anti-Spam Legislation.

## 29.4 PCI-DSS

Future payment services should continue using hosted/tokenized payment
mechanisms.

Current architecture indicates Helcim and Stripe Connect are used so
that card data is not stored directly by the ArtsPond application.

## 29.5 Accessibility

The platform needs to account for:

-   AODA
-   Accessible Canada Act
-   WCAG 2.1 AA

## 29.6 User-Generated Content

When UGC becomes active, moderation and CSAM detection/reporting
requirements must be addressed.

## 29.7 Cross-Border Services

US-based or other external SaaS/tooling may create cross-border data
residency/privacy considerations.

Near-term member personal data is intended to remain in Canadian Azure
regions where practical.

------------------------------------------------------------------------

# 30. Current Cost and Capacity Direction

The Azure nonprofit sponsorship grant has an approximate ceiling of
US\$2,000/year, or roughly US\$167/month.

The current strategy treats the grant as useful for compute runway but
recognizes that:

-   media storage
-   media egress
-   increasing database requirements
-   increased application scale

may eventually exceed the grant.

Cloudflare R2 is part of the longer-term strategy for reducing media
egress cost.

The architecture should therefore track:

> **Cost per active member**

and identify thresholds at which scaling or infrastructure changes
become economically justified.

------------------------------------------------------------------------

# 31. Documentation vs Azure Reconciliation

  -----------------------------------------------------------------------
  Documentation           Azure                   Status
  ----------------------- ----------------------- -----------------------
  `pondMa`                `apo27VM`               Likely same system;
                                                  confirm

  `pondWe`                `vm-pondwe`             Likely same system;
                                                  confirm

  Main VM Canada Central  `apo27VM` Canada        Consistent
                          Central                 

  Main database           `apo27Ssql` Canada East Confirmed

  Main media storage      `apo27stg` Canada       Confirmed
                          Central                 

  Social server           `vm-pondwe` Canada      Confirmed
                          Central                 

  SSH admin IP            `apo27VM-nsg` allows    Discrepancy; effective
  restriction             Any on TCP/22           exposure still unverified

  `vm-pondwe` SSH         `nsg-pondwe` allows     Consistent with documented
  restriction             `45.42.9.75/32`        restricted SSH model

  Webmin admin IP         `apo27VM-nsg` allows    Discrepancy; effective
  restriction             Any on TCP/10000       exposure still unverified

  Cloudflare origin lock  NSGs allow Any on      Requires verification at
                          80/443                 Cloudflare/host layers

  MySQL firewall          3 single-IP rules      Verified; `45.42.9.83`
                                                  purpose remains unknown

  `apo27stg` network      Public, all networks   Confirmed

  `apo27stg` containers   3 Blob, 2 Private     Confirmed

  `apo27stg` recovery     7-day soft delete      Confirmed; versioning/
                                                  backup/PITR disabled

  `apo27stg` RBAC         Reader + Owner visible Partial; complete inventory
                                                  still required

  Social storage network  Public, all networks   Confirmed
  `pondwepixybkruojuww`

  Social storage         2 Blob containers      Confirmed
  containers

  Social storage         Soft delete/versioning  Confirmed; recovery
  protection             disabled                gap for assessment

  Tailscale               UDP/51820 rule exists  Consistent / verify

  Staging environment     Not identified          Gap

  CI/CD                   Not identified          Gap

  Main DB region          Canada East             Confirmed

  Main VM region          Canada Central          Confirmed
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 32. Initial Security/Operational Observations

These are discovery observations and are not yet final risk ratings.

## 32.1 Public IP Exposure

Both application VMs have public IP addresses.

Further verification is required to determine whether the public
interfaces are appropriately protected by:

-   Azure NSGs
-   UFW
-   nginx
-   Cloudflare
-   application controls

## 32.2 SSH

For `apo27VM`, the Azure NSG rule currently permits TCP/22 from any
source. This differs from the documented administrative IP restriction.
Effective exposure remains unverified because the reviewer does not have
server-level access.

For `vm-pondwe`, the subnet NSG restricts TCP/22 to `45.42.9.75/32`.
This is consistent with the documented restricted administrative access
model.

## 32.3 Webmin

For `apo27VM`, Azure NSG permits TCP/10000 from any source. The documented
configuration indicates Webmin should be restricted to administrative IP
addresses. Effective exposure must be verified through server/Cloudflare
controls when authorized access is available.

No Webmin rule was identified in the `nsg-pondwe` rules reviewed.

## 32.4 HTTP/HTTPS

Azure NSG permits TCP/80 and TCP/443 from any source.

This may be intentional because the application is designed around
Cloudflare.

Cloudflare origin-lock enforcement must be verified.

## 32.5 Database Networking

The main MySQL server uses Public Access and does not currently use VNet
integration. Its firewall currently contains three explicit single-IP
allow rules: `45.42.9.83`, `20.48.252.36`, and `20.151.91.13`. The latter
two correspond to the public IPs of `vm-pondwe` and `apo27VM`, respectively.
The purpose of `45.42.9.83` remains to be identified.

## 32.6 Storage Networking and Access

`apo27stg` has public network access enabled from all networks and no
private endpoint or network security perimeter. Blob anonymous access is
enabled at the account level. Three WordPress media containers use
`Blob` anonymous access; `$logs` and `pond-private` are private.

`pondwepixybkruojuww` also has public network access enabled from all
networks, no private endpoint, and no network security perimeter. Both
containers (`pondwe-users` and `wp-media-pondwe`) use `Blob` anonymous
access.

These are configuration observations rather than final vulnerability
ratings because public media delivery and social-platform functionality
may depend on these settings. The data purpose and sensitivity of
`pondwe-users` should be verified before remediation is considered.

## 32.7 Storage Protection

`apo27stg` has blob and container soft delete enabled for seven days.
Blob versioning, Azure Backup for blobs, and point-in-time restore are
not enabled.

`pondwepixybkruojuww` has blob soft delete, container soft delete, blob
versioning, Azure Backup for blobs, point-in-time restore, and change feed
disabled.

The social storage account therefore has a weaker native recovery baseline
and should receive particular attention during the Backup/DR phase.

The reviewer could not list blob data using the portal access-key method
because access is intentionally read-only. This is an expected access
limitation and not a finding.

## 32.8 Regional Placement

The main application VM is in Canada Central while the main database is
in Canada East.

This should be assessed for latency, security, availability, cost, and
data residency.

## 32.9 Staging

No staging environment has been identified.

This is a significant operational gap for safe patching and
infrastructure changes.

## 32.10 Restore Testing

Backups exist according to documentation, but a successful restore drill
has not yet been performed.

------------------------------------------------------------------------

# 33. Access and Ownership Considerations

The intended access model follows staged least privilege:

1.  Named individual account.
2.  MFA.
3.  Read-only access first.
4.  Sandbox before production.
5.  Production access through an approved/paired process.

Current discovery should identify:

-   Azure subscription owners
-   Resource group owners
-   VM administrators
-   Cloudflare administrators
-   GitHub repository administrators
-   Database administrators
-   Backup administrators
-   Application owners
-   Payment service administrators
-   DNS administrators

An access/ownership matrix should be created as a separate Phase 0
deliverable.

------------------------------------------------------------------------

# 34. Secrets and Credential Handling

Previous audit documentation indicates that two live secrets were
exposed in an audit transcript:

-   Azure MySQL administrator password
-   Azure Storage account key

These credentials were identified for rotation.

This should be treated as a security incident/credential hygiene item
requiring verification that rotation has actually been completed.

Future secret management should favor:

-   Azure Key Vault
-   managed identities where supported
-   short-lived credentials
-   removal of secrets from source code
-   removal of secrets from transcripts/documentation
-   least-privilege credentials

------------------------------------------------------------------------

# 35. Source Control / DevOps State

Current documentation indicates that:

-   A canonical repository exists on the main VM.
-   The repository has been cloned to several team machines.
-   GitHub status at the time of documentation was not yet confirmed.

This must be re-verified because the previous documentation may be
stale.

There is currently no confirmed CI/CD pipeline.

The intended future workflow is:

``` text
Developer
    |
    v
GitHub
    |
    v
CI validation
    |
    v
Development / Test
    |
    v
Staging
    |
    v
Approval
    |
    v
Production
```

Infrastructure should eventually be represented through Bicep and
deployed through controlled pipelines.

------------------------------------------------------------------------

# 36. Open Discovery Items

## Azure

-   [ ] Inspect `apo27VM-nsg` effective security rules.
-   [x] Inspect `nsg-pondwe` individual inbound rules.
-   [ ] Inspect `nsg-pondwe` effective security rules.
-   [x] Inspect Azure MySQL firewall rules.
-   [x] Inspect Azure MySQL network configuration.
-   [x] Inspect `apo27stg` container access levels.
-   [x] Inspect `apo27stg` networking.
-   [x] Inspect `apo27stg` data protection and security configuration.
-   [x] Inspect `pondwepixybkruojuww` container access levels.
-   [x] Inspect `pondwepixybkruojuww` networking.
-   [x] Inspect `pondwepixybkruojuww` data protection and security configuration.
-   [ ] Verify Blob versioning requirements.
-   [ ] Review Azure Monitor thresholds.
-   [ ] Review alert destinations and ownership.
-   [ ] Complete Azure RBAC/access inventory.
-   [ ] Review VM managed identity configuration.
-   [ ] Review public IP configuration.
-   [ ] Verify Cloudflare origin IP restrictions.
-   [ ] Verify current GitHub/source repository status.
-   [ ] Verify current credential rotation status.

## VM-level

Requires authorized server access:

-   [ ] Verify UFW on `apo27VM`.
-   [ ] Verify SSH configuration.
-   [ ] Verify nginx configuration.
-   [ ] Verify Fail2ban.
-   [ ] Verify Tailscale.
-   [ ] Verify Webmin access controls.
-   [ ] Verify PHP-FPM.
-   [ ] Verify Redis.
-   [ ] Verify WordPress configuration.
-   [ ] Verify local MySQL and dependency status.
-   [ ] Verify backup scripts and schedules.

## Application

-   [ ] Verify OIDC/SSO implementation.
-   [ ] Verify payment integration details.
-   [ ] Verify Cloudflare Worker media path.
-   [ ] Identify all application owners.
-   [ ] Identify all external service owners.
-   [ ] Confirm application data flows.
-   [ ] Confirm current production domains and DNS records.

------------------------------------------------------------------------

# 37. Current Discovery Status

## Completed

-   [x] Application overview
-   [x] Main WordPress architecture
-   [x] WordPress Multisite inventory
-   [x] Social platform identification
-   [x] Main request/data flow
-   [x] External dependency inventory
-   [x] Environment model
-   [x] Business/growth context
-   [x] Target architecture direction
-   [x] Azure resource groups identified
-   [x] Main VM inventory
-   [x] Social VM inventory
-   [x] Main Azure MySQL inventory
-   [x] Storage account inventory
-   [x] VNet inventory
-   [x] Main VM NSG rules captured
-   [x] Social VM/subnet NSG rules captured
-   [x] Azure MySQL firewall rules captured
-   [x] Azure MySQL network configuration captured
-   [x] `apo27stg` container access levels captured
-   [x] `apo27stg` networking configuration captured
-   [x] `apo27stg` data protection configuration captured
-   [x] `apo27stg` security configuration captured
-   [x] `apo27stg` RBAC partially reviewed
-   [x] `pondwepixybkruojuww` storage security review
-   [x] Initial documentation-vs-Azure reconciliation
-   [x] Current read-only access limitation documented
-   [x] Backup/DR baseline documented
-   [x] Initial security observations documented

## In Progress

-   [ ] Effective NSG security analysis
-   [ ] Complete Azure RBAC/access inventory
-   [ ] Cloudflare origin protection verification
-   [ ] Server-level firewall verification
-   [ ] Ownership matrix

## Not Yet Started

-   [ ] Phase 0.1C --- Architecture/data-flow mapping
-   [ ] Phase 0.1D --- Final reconciliation
-   [ ] Phase 0 Discovery Report
-   [ ] Phase 1 --- Security Review & Hardening Policy

------------------------------------------------------------------------

# 38. Recommended Phase 0 Deliverables

The following manager-facing deliverables should be produced from the
discovery work:

1.  `ArtsPond_Current_Infrastructure_Inventory.xlsx`
2.  `ArtsPond_Current_State_Architecture.pdf`
3.  `ArtsPond_Access_Ownership_Matrix.xlsx`
4.  `ArtsPond_Phase_0_Discovery_Report.docx` or `.pdf`
5.  `0.1-application-discovery.md`

The Markdown document serves as the working technical record and
evidence base for the other deliverables.

------------------------------------------------------------------------

# 39. Discovery Principle

No security remediation should be performed solely on the basis of an
unverified observation.

For every potential issue:

1.  Identify the configuration.
2.  Verify effective behavior.
3.  Determine business/application dependency.
4.  Assess risk.
5.  Recommend remediation.
6.  Obtain approval before changing production.

This prevents accidental disruption of the existing ArtsPond platform
while establishing an evidence-based security baseline.

------------------------------------------------------------------------

# 40. Immediate Next Step

Because the reviewer has intentionally been granted read-only Azure
access and does not have server-level access, discovery should continue
through Azure Portal and authorized evidence supplied by system owners.

The next practical activity is:

> **Azure Portal → Access control (IAM) → Role assignments**

The objective is to build the broader Azure access/ownership picture
across the relevant subscription and resource groups without requesting
elevated permissions.

The following items remain open for later verification as access permits:

-   Effective Azure NSG behavior for `apo27VM` and `vm-pondwe`
-   Cloudflare origin protection
-   Server-level firewall and service configuration
-   Complete Azure RBAC inventory
-   Application/service ownership
-   GitHub/source-control status
-   Credential rotation status

No production configuration changes should be made during this
verification phase.


# 40. Current Discovery Status — Updated 2026-09-03

## 40.1 Completed / Verified

The following Azure-side discovery activities have now been completed or
substantially verified through the reviewer's Reader access:

-   Main Azure VM inventory and networking for `apo27VM`.
-   Main VM NSG inbound and outbound rules.
-   Azure MySQL networking and firewall rules for `apo27Ssql`.
-   Azure MySQL database inventory: five user databases and four system
    databases.
-   Selected MySQL server parameters.
-   Main storage account networking, container access, data protection,
    configuration, and partial RBAC.
-   Social VM inventory and subnet-level NSG rules.
-   Social storage networking, container access, data protection, and
    configuration.
-   Resource-group RBAC for `apo27` and `apo28`.
-   Azure Monitor alert configuration for `apo27VM`.
-   Absence of Azure Monitor alert rules and VM extensions on `vm-pondwe`.

## 40.2 Confirmed Gaps / Observations

-   `apo27VM` Azure NSG permits inbound SSH and Webmin from Any source;
    host-level and Cloudflare controls remain unverified.
-   `apo27VM` outbound TCP/3306 and UDP/51820 have broad destination
    scope.
-   `vm-pondwe` has no Azure Monitor alert rules configured.
-   `vm-pondwe` has no VM extensions identified.
-   `pondwepixybkruojuww` has no blob/container soft delete, versioning,
    point-in-time restore, Azure Backup for blobs, or change feed enabled.
-   Both storage accounts use public network access; anonymous Blob access
    is enabled where documented above. Application justification must be
    validated before remediation.

## 40.3 Access-Limited / Unverified Items

The following remain outside the reviewer's current independent
verification boundary:

-   Cloudflare DNS/WAF/DDoS/TLS and origin-lock configuration.
-   Server-level UFW, SSH, nginx, fail2ban, Webmin, Tailscale, PHP-FPM,
    Redis, WordPress, and local MySQL configuration.
-   Active Azure Backup protection/last backup for `vm-pondwe`.
-   Complete subscription-wide Azure RBAC inventory.
-   Purpose and ownership of `45.42.9.83` MySQL firewall access.
-   Purpose/ownership of the additional MySQL databases `pondpdb`,
    `pondco`, and `pondwebdb`.
-   Application-level purpose/data sensitivity of the `pondwe-users`
    storage container.

These are recorded as **verification limitations**, not automatically as
security vulnerabilities.

## 40.4 Next Discovery Activities

The next activities should focus on closing the remaining evidence gaps
that can be addressed through documentation or authorized owners, rather
than requesting elevated access from the reviewer:

1. Confirm the `pondMa` ↔ `apo27VM` mapping through approved evidence.
2. Reconcile application/service ownership for the Azure resources.
3. Verify the purpose of the MySQL firewall IP `45.42.9.83`.
4. Verify the purpose of the additional MySQL user databases.
5. Obtain authorized evidence for Cloudflare origin protection.
6. Obtain authorized evidence for host-level firewall and service
   controls.
7. Obtain authorized evidence of `vm-pondwe` backup protection.
8. Verify development/test/staging infrastructure and deployment
   workflow.
9. Consolidate the findings into the Phase 0 Discovery Report and
   Access/Ownership Matrix.

**No production configuration changes should be made as part of these
remaining discovery activities.**

