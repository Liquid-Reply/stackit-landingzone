<img src=".github/img/RunningMan_lila.png" alt="Liquid Reply" width="120" />

# STACKIT Landing Zone

A Terraform-based landing zone for STACKIT that provisions a hub & spoke network topology, centralized shared services, folder-based IAM, and a self-service project factory for application teams.

## About Liquid Reply x STACKIT

Liquid Reply is a STACKIT partner focused on sovereign cloud, Kubernetes, platform engineering, and cloud transformation. By combining STACKIT's sovereign cloud services with Liquid Reply's cloud-native expertise, organizations can accelerate modernization initiatives while maintaining security, compliance, and European data sovereignty.

---

## Table of Contents

- [Getting Started](#getting-started)
- [Hub & Spoke Architecture](#hub--spoke-architecture)
- [Access Model](#access-model)
- [Self-Service Project Requests](#self-service-project-requests)
- [Makefile Targets](#makefile-targets)

---

## Getting Started

### Prerequisites

| Requirement | Notes |
|---|---|
| Terraform >= 1.7 | [Install](https://developer.hashicorp.com/terraform/install) |
| STACKIT account | With an existing **organization** and a **management project** |
| STACKIT CLI (optional) | For creating the initial service account |

### 1. Create the bootstrap service account

The landing zone authenticates via **key-flow** (RSA key pair). You need a service account with `owner` permissions on your management project.

**Via the STACKIT Portal:**

1. Navigate to your **management project** in the [STACKIT Portal](https://portal.stackit.cloud)
2. Go to **Service Accounts** and create a new service account (e.g. `sa-terraform-bootstrap`)
3. Assign the `owner` role on the management project and the `owner` role on the organization
4. Create a **service account key** (key-flow):
   - Download the **key JSON** and save it to `sa-key.json`
   - Download the **RSA private key** (PEM) and save it to `sa-key.pem`

**Via the STACKIT CLI:**

```bash
# Authenticate
stackit auth login

# Create the service account in your management project
stackit service-account create \
  --project-id <MANAGEMENT_PROJECT_ID> \
  --name sa-terraform-bootstrap

# Note the service account email from the output, then assign org-level owner
stackit organization role assign \
  --organization-id <ORG_ID> \
  --role owner \
  --subject <SA_EMAIL>

# Create the key pair
stackit service-account key create \
  --project-id <MANAGEMENT_PROJECT_ID> \
  --service-account-email <SA_EMAIL> \
  --output-dir ~/.stackit
```

Ensure the files are protected:

```bash
chmod 600 sa-key.json sa-key.pem
```

### 2. Configure the bootstrap layer

Edit `00-bootstrap/terraform.tfvars`:

```hcl
region                   = "eu01"
service_account_key_path = "sa-key.json"
private_key_path         = "sa-key.pem"
management_project_id    = "<YOUR_MANAGEMENT_PROJECT_ID>"
state_bucket_name        = "lz-tfstate"
audit_bucket_name        = "lz-audit-logs"
credential_expiration    = "2027-12-31T23:59:59Z"
```

### 3. Deploy the layers in order

Each layer builds on the outputs of the previous one. They **must** be applied sequentially the first time.

```bash
# Layer 0 -- State backend (uses local state)
make bootstrap

# Layer 1 -- Hub project, network area, DNS, gateway, IAM
#   Edit 01-hub/terraform.tfvars first (org_id, owner_email, DNS, gateway image, SSH key, etc.)
make hub

# Layer 2 -- Spoke environments (dev, staging, prod)
#   Edit 02-spokes/envs/{dev,staging,prod}.tfvars first
make spokes          # all three, or:
make spoke-dev       # single environment

# Layer 3 -- Team projects from YAML requests
make projects
```

After bootstrap completes, note the S3 credentials from the output. These are used by all subsequent layers to store state remotely:

```bash
cd 00-bootstrap
terraform output -json state_access_key
terraform output -json state_secret_key
```

Export them so the S3 backend can authenticate:

```bash
export AWS_ACCESS_KEY_ID="<state_access_key>"
export AWS_SECRET_ACCESS_KEY="<state_secret_key>"
```

---

## Hub & Spoke Architecture

### How it works

The landing zone uses **per-environment STACKIT Network Areas (SNAs)** to create isolated routed networks. Each environment (dev, staging, prod) has its own SNA, providing **L3-level isolation** between stages. Projects within the same environment share an SNA and can communicate over private IPs without any additional peering.

```
                    STACKIT Organization
                            |
              +-------------+-------------+
              |                           |
       platform/ folder             teams/ folder
              |                           |
    +---------+---------+          +------+------+
    |         |         |          |      |      |
   Hub      Dev      Staging     team   team   team
  Project   Spoke     Spoke      alpha  alpha  beta
  (VPN,     (own      (own       dev    prod   dev
   DNS,      SNA)      SNA)
   SAs)      |
            Prod
            Spoke
            (own SNA)

Each environment has its own SNA (no L3 route between them)
  -> Routed networks get automatic L3 connectivity within an env
  -> Hub provides DNS, VPN, and shared service accounts
```

### Network flow

1. **Network Areas** are created per environment in the spoke layer (dev-sna, staging-sna, prod-sna)
2. **Spoke projects** are labeled with their environment's `networkArea = <SNA_ID>` and get a routed network
3. **Team projects** (from the project factory) are labeled with the same SNA ID as their environment
4. Any routed network created inside an SNA-labeled project automatically gets L3 connectivity to all other networks in the same SNA
5. There is **no routing path between environments** - each SNA is an isolated L3 domain

### What lives in the hub

| Service | Purpose |
|---|---|
| **NetBird VPN** | Self-hosted WireGuard management server on an isolated network (no SNA) |
| **STACKIT site-to-site VPN** | Optional managed IPsec/IKEv2 service, deployed per spoke to connect that environment's SNA to a remote network |
| **DNS root zone** | Root zone for the landing zone; spokes create NS-delegated sub-zones |
| **Service accounts** | `sa-cicd` (deployments) and `sa-monitoring` (metric scraping) |

### What lives in each spoke

| Service | Purpose |
|---|---|
| **Gateway** | NetBird subnet router / SSH bastion (no public IP when VPN is enabled) |
| **DNS sub-zone** | Environment sub-zone (e.g. `dev.stackit-lz-demo.org`), NS-delegated from hub |
| **Observability** | Per-environment Prometheus + Grafana instance *(currently disabled, planned)* |

### Security groups

Every spoke and team project receives default security groups:

| Rule | Direction | Protocol | Source / Dest | Ports |
|---|---|---|---|---|
| Allow HTTPS from spoke | Ingress | TCP | `<spoke prefix>` | 443 |
| Allow SSH from spoke | Ingress | TCP | `<spoke prefix>` | 22 |
| Allow all egress | Egress | any | any | any |

Security groups affect a workload only after its network interface attaches them.
The project factory exports the required group IDs for workload modules; it
cannot attach groups to infrastructure created later by teams outside this
repository. Teams can request additional reviewed ingress rules through the
project-request workflow.

### Managed site-to-site VPN

An environment can optionally use STACKIT's managed site-to-site VPN service.
It is deployed in the spoke project, where it connects that environment's SNA
to a remote router using two IPsec/IKEv2 tunnels and BGP. This preserves the
isolation between dev, staging, and production. It is separate from NetBird and
does not enable it automatically. See [the site-to-site VPN runbook](docs/site-to-site-vpn.md)
for activation, remote-site configuration, route filtering, testing, and PSK
rotation.

---

## Access Model

IAM is managed through **folder-level role inheritance**. Roles assigned on a folder are automatically inherited by every project inside that folder. Roles in STACKIT are **additive** -- they cascade downward and cannot be revoked at a lower level.

### Folder structure and role inheritance

```
Organization
├── platform/                              # Managed by platform team
│   ├── IAM: platform team = owner ──────> inherited by hub + all spokes
│   │
│   ├── Hub Project
│   │   └── IAM: sa-monitoring = reader
│   │
│   ├── Spoke: dev
│   │   └── IAM: developers = editor       (can deploy)
│   │
│   ├── Spoke: staging
│   │   └── IAM: developers = reader       (can view, not deploy)
│   │
│   └── Spoke: prod
│       └── IAM: (no additional roles)      (platform team only)
│
└── teams/                                 # Self-service team projects
    ├── IAM: sa-monitoring = reader ──────> inherited by ALL team projects
    │
    ├── team-alpha-dev
    │   └── IAM: alpha-lead = owner, alpha-dev = editor
    │
    ├── team-alpha-prod
    │   └── IAM: alpha-lead = owner, alpha-dev = reader
    │
    └── team-beta-dev
        └── IAM: beta-lead = owner, beta-dev = editor
```

### Role reference

| Role | Permissions |
|---|---|
| **owner** | Full access to all resources + can manage IAM role assignments |
| **editor** | Create, modify, and delete resources (no IAM management) |
| **team-editor** | Custom role: same as editor but **without** public IP and IAM permissions |
| **reader** | Read-only access to all resources |

### Custom RBAC: the `team-editor` role

Instead of giving teams the built-in `editor` (which allows creating public IPs and managing IAM), the landing zone creates a **custom `team-editor` role** per project. This role includes all editor permissions except:

| Denied permission | Why |
|---|---|
| `iaas.public-ip.create` | Prevents exposing workloads to the internet |
| `iaas.public-ip.delete` | Prevents removing platform-managed public IPs |
| `iaas.public-ip.update` | Prevents modifying public IP configuration |
| `iaas.server.public-ip.add` | Prevents attaching public IPs to VMs |
| `iaas.server.public-ip.remove` | Prevents detaching platform-managed associations |
| `iam.member.add` | Prevents privilege escalation |
| `iam.member.remove` | Prevents removing platform SA access |
| `iam.role.*` | Prevents creating/modifying custom roles |
| `iam.service-account.create/delete` | Prevents creating SAs for privilege escalation |
| `iam.service-account.impersonate/act-as` | Prevents SA impersonation |
| `iam.service-account-key.*` (create/delete/edit) | Prevents generating SA credentials |
| `iam.service-account-federation.*` (create/delete/edit) | Prevents SA federation setup |
| `iam.service-account-token.*` (create/delete) | Prevents SA token generation |

Teams can still use the STACKIT Portal and API freely for everything else -- VMs, SKE clusters, databases, object storage, DNS records, etc.

To generate the permissions list from the live API:

```bash
# Discover all available permissions
./scripts/discover-permissions.sh project

# Generate the team-editor permissions (editor minus denied)
./scripts/generate-team-role-permissions.sh > 03-projects/team-editor-permissions.auto.tfvars
```

### Who can access what

| Identity | Hub | Dev Spoke | Staging Spoke | Prod Spoke | Team Projects |
|---|---|---|---|---|---|
| **Platform team** | owner | owner (inherited) | owner (inherited) | owner (inherited) | -- |
| **SA CI/CD** | editor | editor | editor | editor | -- |
| **SA Monitoring** | reader | reader | reader | reader | reader (folder) |
| **Developers** | -- | editor | reader | -- | per YAML |
| **Team leads** | -- | -- | -- | -- | owner (per YAML) |
| **Team members** | -- | -- | -- | -- | team-editor (per YAML) |

Key points:

- **Prod is locked down** -- only the platform team (via folder inheritance) and the CI/CD service account can make changes. No individual developer has direct access.
- **Staging is read-only for developers** -- they can inspect resources but must deploy through CI/CD.
- **Dev is open for developers** -- they have editor access for fast iteration.
- **Team projects inherit monitoring access automatically** -- the monitoring SA role is assigned on the `teams/` folder so every new project gets read access without per-project configuration. CI/CD access is a per-team responsibility and must be granted explicitly.
- **Team members get `team-editor`** -- when `team_editor_permissions` is configured, any YAML request for `editor` is automatically remapped to the restricted `team-editor` custom role. Teams keep full UI access but cannot create public IPs or escalate permissions.

---

## Self-Service Project Requests

Application teams can request their own STACKIT project by submitting a YAML file via Pull Request.

### How to request a project

1. Copy the template:

```bash
cp 03-projects/requests/_template.yaml 03-projects/requests/<team>-<env>.yaml
```

2. Fill in the fields:

```yaml
project_name: "team-phoenix-dev"
team: "phoenix"
environment: "dev"
owner_email: "phoenix-lead@example.com"

members:
  - email: "phoenix-lead@example.com"
    role: "owner"
  - email: "phoenix-dev1@example.com"
    role: "editor"

extra_labels:
  cost_center: "cc-4200"
  application: "phoenix-api"
```

3. Open a Pull Request. The platform team reviews and merges.

4. CI/CD runs `terraform apply` in `03-projects/`, which provisions:

| What | Details |
|---|---|
| STACKIT project | Under `teams/` folder, labeled with SNA for network connectivity |
| Routed network | Automatic L3 connectivity to all projects in the same environment |
| Security groups | HTTPS + SSH from spoke allowed, all egress allowed |
| Team IAM | Roles exactly as specified in the YAML `members` list |
| SA access | Monitoring (reader) inherited from `teams/` folder |

---

## Makefile Targets

```
make bootstrap       Apply bootstrap layer (state backend)
make hub             Apply hub layer (shared services)
make spoke-dev       Apply a single spoke environment
make spoke-staging
make spoke-prod
make spokes          Apply all spoke environments
make projects        Apply project factory (team projects from YAML)
make fmt             Format all Terraform files
make validate        Validate all layers
make clean           Remove .terraform directories
```

---

## State Layout

All Terraform state is stored in the `lz-tfstate` S3 bucket on STACKIT Object Storage:

```
lz-tfstate/
├── bootstrap/terraform.tfstate
├── hub/terraform.tfstate
├── spokes/
│   ├── dev/terraform.tfstate
│   ├── staging/terraform.tfstate
│   └── prod/terraform.tfstate
└── projects/terraform.tfstate
```

Each layer is independent -- you can plan/apply a single layer without affecting others. Cross-layer references use `terraform_remote_state` data sources.

---

## Connect with Liquid Reply

| Channel | Link |
|---|---|
| Website | [liquidreply.com](https://www.reply.com/liquid-reply/en) |
| Blog | [liquidreply.net](https://liquidreply.net/) |
| LinkedIn | [Liquid Reply](https://www.linkedin.com/company/liquid-reply/) |
| X (Twitter) | [@LiquidReply](https://x.com/LiquidReply) |
