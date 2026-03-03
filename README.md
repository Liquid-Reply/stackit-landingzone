# STACKIT Landing Zone

A Terraform-based landing zone for STACKIT that provisions a hub & spoke network topology, centralized shared services, folder-based IAM, and a self-service project factory for application teams.

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

# Layer 1 -- Hub project, network area, DNS, observability, bastion, IAM
#   Edit 01-hub/terraform.tfvars first (org_id, owner_email, DNS, bastion image, SSH key, etc.)
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

The landing zone uses a **STACKIT Network Area (SNA)** to create a routed hub & spoke network. All projects that share the same SNA can communicate over private IPs without any additional peering or VPN setup.

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
             |         |          dev    prod   dev
            Prod
            Spoke

All projects share the same Network Area (SNA)
  -> Routed networks get automatic L3 connectivity
  -> Hub acts as central point for shared services
```

### Network flow

1. **Network Area** is created at the organization level in the hub layer
2. **Hub project** is labeled with `networkArea = <SNA_ID>` and gets a routed network
3. **Spoke projects** (and team projects) are also labeled with the same SNA ID
4. Any routed network created inside an SNA-labeled project automatically gets L3 connectivity to all other networks in the same SNA

### What lives in the hub

| Service | Purpose |
|---|---|
| **Bastion host** | SSH jump server with a public IP -- the only ingress point from the internet |
| **DNS zone** | Root zone for the landing zone; spokes register `*.<env>` wildcard records |
| **Observability** | Centralized Prometheus + Grafana instance; spokes register scrape targets |
| **Service accounts** | `sa-cicd` (deployments) and `sa-monitoring` (metric scraping) |

### Security groups

Every spoke and team project is provisioned with three default security groups:

| Rule | Direction | Protocol | Source / Dest | Ports |
|---|---|---|---|---|
| Allow HTTPS from hub | Ingress | TCP | `10.0.0.0/8` | 443 |
| Allow SSH from hub | Ingress | TCP | `10.0.0.0/8` | 22 |
| Allow all egress | Egress | any | any | any |

No other inbound traffic is permitted by default. Teams can add additional security groups in their own projects.

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
│   │   └── IAM: sa-cicd = editor, sa-monitoring = reader
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
    ├── IAM: sa-cicd = editor ────────────> inherited by ALL team projects
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
| **SA CI/CD** | editor | editor | editor | editor | editor (folder) |
| **SA Monitoring** | reader | reader | reader | reader | reader (folder) |
| **Developers** | -- | editor | reader | -- | per YAML |
| **Team leads** | -- | -- | -- | -- | owner (per YAML) |
| **Team members** | -- | -- | -- | -- | team-editor (per YAML) |

Key points:

- **Prod is locked down** -- only the platform team (via folder inheritance) and the CI/CD service account can make changes. No individual developer has direct access.
- **Staging is read-only for developers** -- they can inspect resources but must deploy through CI/CD.
- **Dev is open for developers** -- they have editor access for fast iteration.
- **Team projects inherit SA access automatically** -- assigning roles on the `teams/` folder means every new project gets CI/CD and monitoring access without any per-project configuration.
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
| Routed network | Automatic L3 connectivity to hub and all spokes |
| Security groups | HTTPS + SSH from hub allowed, all egress allowed |
| Team IAM | Roles exactly as specified in the YAML `members` list |
| SA access | CI/CD (editor) + Monitoring (reader) inherited from `teams/` folder |

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
