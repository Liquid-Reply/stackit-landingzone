# STACKIT Landing Zone — Architecture

## High-Level Overview

```mermaid
graph TB
    subgraph org["STACKIT Organization"]
        direction TB

        subgraph mgmt["Management Project"]
            tfstate["S3: lz-tfstate<br/><i>Terraform State</i>"]
            audit["S3: lz-audit-logs<br/><i>Audit Trail</i>"]
        end

        subgraph platform["Folder: platform/"]
            direction TB

            subgraph hub["Hub Project (no network)"]
                direction LR
                dns_root["DNS: example.com<br/><i>Root zone</i>"]
                sa_cicd["SA: CI/CD"]
                sa_mon["SA: Monitoring"]
            end

            subgraph sna_dev["SNA: dev (10.0.0.0/16)"]
                spoke_dev["Spoke: dev<br/><i>Bastion + Observability</i><br/><i>DNS: dev.example.com</i>"]
            end

            subgraph sna_stg["SNA: staging (10.1.0.0/16)"]
                spoke_stg["Spoke: staging<br/><i>Bastion + Observability</i><br/><i>DNS: stg.example.com</i>"]
            end

            subgraph sna_prod["SNA: prod (10.2.0.0/16)"]
                spoke_prod["Spoke: prod<br/><i>Bastion + Observability</i><br/><i>DNS: prod.example.com</i>"]
            end
        end

        subgraph teams["Folder: teams/"]
            direction TB
            subgraph dev_teams["Dev Team Projects"]
                alpha_dev["team-alpha-dev"]
                beta_dev["team-beta-dev"]
            end
            subgraph prod_teams["Prod Team Projects"]
                alpha_prod["team-alpha-prod"]
            end
        end
    end

    hub -->|"SA emails,<br/>DNS root zone"| spoke_dev & spoke_stg & spoke_prod

    alpha_dev -.->|"SNA: dev"| sna_dev
    beta_dev -.->|"SNA: dev"| sna_dev
    alpha_prod -.->|"SNA: prod"| sna_prod

    sna_dev -.->|"No L3 route"| sna_stg
    sna_stg -.->|"No L3 route"| sna_prod

    style org fill:#f0f4ff,stroke:#4a6fa5,stroke-width:2px
    style hub fill:#fff3e0,stroke:#e65100,stroke-width:2px
    style mgmt fill:#f3e5f5,stroke:#7b1fa2,stroke-width:1px
    style platform fill:#fff8e1,stroke:#f9a825,stroke-width:1px
    style teams fill:#fce4ec,stroke:#c62828,stroke-width:1px
    style sna_dev fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    style sna_stg fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
    style sna_prod fill:#fce4ec,stroke:#c62828,stroke-width:2px
    style dev_teams fill:#e3f2fd,stroke:#1565c0,stroke-width:1px
    style prod_teams fill:#fce4ec,stroke:#c62828,stroke-width:1px

    linkStyle 6 stroke:#d32f2f,stroke-width:2px
    linkStyle 7 stroke:#d32f2f,stroke-width:2px
```

## What Each Project Gets (Project Factory)

Every team project is provisioned with identical guardrails via a YAML request:

```mermaid
graph LR
    subgraph factory["Project Factory Output"]
        direction TB
        proj["STACKIT Project<br/><i>Attached to env SNA via label</i>"]
        net["Routed Network<br/><i>Private L3 within environment</i>"]
        sg["Security Groups<br/><i>Spoke-only ingress</i>"]
        fw["Firewall Rules<br/><i>PR-approved cross-project access</i>"]
        role["Custom RBAC<br/><i>team-editor: no public IP,<br/>no SG changes, no IAM escalation</i>"]
        dns_zone["Delegated DNS Zone<br/><i>Self-service via portal</i>"]
        labels["Labels<br/><i>team, env, cost_center</i>"]
    end

    proj --> net --> sg --> fw --> role --> dns_zone --> labels

    style factory fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
```

## Network Isolation

Each environment has its own STACKIT Network Area (SNA), providing **L3-level isolation** between dev, staging, and prod. There is no routing path between environments — isolation is enforced at the network layer, not just by security groups.

```mermaid
graph TB
    subgraph sna_dev["SNA: dev-sna (10.0.0.0/16)"]
        direction TB

        subgraph spoke_dev_net["Spoke: dev (10.0.0.0/24)"]
            bastion_dev["Bastion"]
            prom_dev["Observability"]
        end

        subgraph dev_projects["Dev Projects"]
            alpha_dev["team-alpha-dev<br/>10.0.1.0/24"]
            beta_dev["team-beta-dev<br/>10.0.2.0/24"]
        end

        bastion_dev -->|"SSH :22"| alpha_dev
        bastion_dev -->|"SSH :22"| beta_dev
        prom_dev -->|"Scrape :9090"| alpha_dev
        prom_dev -->|"Scrape :9090"| beta_dev
    end

    subgraph sna_prod["SNA: prod-sna (10.2.0.0/16)"]
        direction TB

        subgraph spoke_prod_net["Spoke: prod (10.2.0.0/24)"]
            bastion_prod["Bastion"]
            prom_prod["Observability"]
        end

        subgraph prod_projects["Prod Projects"]
            alpha_prod["team-alpha-prod<br/>10.2.1.0/24"]
        end

        bastion_prod -->|"SSH :22"| alpha_prod
        prom_prod -->|"Scrape :9090"| alpha_prod
    end

    sna_dev -.->|"NO L3 ROUTE<br/>Different network areas"| sna_prod

    style sna_dev fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    style sna_prod fill:#fce4ec,stroke:#c62828,stroke-width:2px
    style spoke_dev_net fill:#fff3e0,stroke:#e65100,stroke-width:2px
    style spoke_prod_net fill:#fff3e0,stroke:#e65100,stroke-width:2px
    style dev_projects fill:#e3f2fd,stroke:#1565c0,stroke-width:1px
    style prod_projects fill:#fce4ec,stroke:#c62828,stroke-width:1px

    linkStyle 6 stroke:#d32f2f,stroke-width:3px
```

**How isolation works:**
- Each environment is a separate L3 routing domain — **no routing path between dev/staging/prod**
- SG ingress rules only allow the spoke network's prefix (same-environment traffic)
- Teams cannot modify security groups (permission denied via custom RBAC)
- Cross-project access within the same environment requires a `firewall_rules` entry in YAML, approved via PR
- No public IPs allowed (permission denied via custom RBAC)

## DNS Delegation

```mermaid
graph TB
    root["Hub: example.com<br/><i>Root zone in hub project</i>"]

    root -->|"NS delegation"| dev_zone["Spoke: dev.example.com<br/><i>Sub-zone in spoke-dev project</i>"]
    root -->|"NS delegation"| prod_zone["Spoke: prod.example.com<br/><i>Sub-zone in spoke-prod project</i>"]

    dev_zone -->|"NS delegation"| alpha_dev_zone["team-alpha-dev.dev.example.com<br/><i>Zone in team's own project</i>"]
    dev_zone -->|"NS delegation"| beta_dev_zone["team-beta-dev.dev.example.com<br/><i>Zone in team's own project</i>"]

    prod_zone -->|"NS delegation"| alpha_prod_zone["team-alpha-prod.prod.example.com<br/><i>Zone in team's own project</i>"]

    alpha_dev_zone -->|"Team self-service<br/>via STACKIT portal"| records_dev["api.team-alpha-dev.dev.example.com<br/>app.team-alpha-dev.dev.example.com"]

    alpha_prod_zone -->|"Team self-service<br/>via STACKIT portal"| records_prod["api.team-alpha-prod.prod.example.com<br/>app.team-alpha-prod.prod.example.com"]

    style root fill:#fff3e0,stroke:#e65100,stroke-width:2px
    style dev_zone fill:#e3f2fd,stroke:#1565c0,stroke-width:1px
    style prod_zone fill:#fce4ec,stroke:#c62828,stroke-width:1px
    style alpha_dev_zone fill:#e8f5e9,stroke:#2e7d32,stroke-width:1px
    style beta_dev_zone fill:#e8f5e9,stroke:#2e7d32,stroke-width:1px
    style alpha_prod_zone fill:#e8f5e9,stroke:#2e7d32,stroke-width:1px
    style records_dev fill:#f5f5f5,stroke:#9e9e9e,stroke-width:1px
    style records_prod fill:#f5f5f5,stroke:#9e9e9e,stroke-width:1px
```

## IAM Model

```mermaid
graph TB
    org["STACKIT Organization"]

    org --> folder_platform["Folder: platform/<br/><i>Platform team: owner</i><br/><small>inherited by all children</small>"]
    org --> folder_teams["Folder: teams/<br/><i>SA CI/CD: editor</i><br/><i>SA Monitoring: reader</i><br/><small>inherited by all team projects</small>"]

    folder_platform --> hub_proj["Hub Project<br/><i>DNS root zone, SAs</i><br/><i>(no network)</i>"]
    folder_platform --> spoke_dev_proj["Spoke: dev<br/><i>SNA + Network + DNS sub-zone</i><br/><i>Bastion + Observability</i>"]
    folder_platform --> spoke_prod_proj["Spoke: prod<br/><i>SNA + Network + DNS sub-zone</i><br/><i>Bastion + Observability</i>"]

    folder_teams --> alpha_dev_proj["team-alpha-dev<br/><i>alpha-lead: owner</i><br/><i>alpha-dev1: <b>team-editor</b></i>"]
    folder_teams --> alpha_prod_proj["team-alpha-prod<br/><i>alpha-lead: owner</i><br/><i>alpha-dev1: reader</i>"]
    folder_teams --> beta_dev_proj["team-beta-dev<br/><i>beta-lead: owner</i><br/><i>beta-dev1: <b>team-editor</b></i>"]

    subgraph restricted["team-editor = editor MINUS:"]
        direction LR
        no_pubip["Public IP<br/>create/delete"]
        no_sg["Security Group<br/>create/modify/delete"]
        no_iam["IAM roles<br/>add/remove"]
        no_sa["Service Accounts<br/>create/delete"]
    end

    style org fill:#f0f4ff,stroke:#4a6fa5,stroke-width:2px
    style folder_platform fill:#fff8e1,stroke:#f9a825,stroke-width:2px
    style folder_teams fill:#fce4ec,stroke:#c62828,stroke-width:2px
    style restricted fill:#ffebee,stroke:#d32f2f,stroke-width:2px
    style hub_proj fill:#fff3e0,stroke:#e65100,stroke-width:1px
    style alpha_dev_proj fill:#e3f2fd,stroke:#1565c0,stroke-width:1px
    style alpha_prod_proj fill:#e3f2fd,stroke:#1565c0,stroke-width:1px
    style beta_dev_proj fill:#e3f2fd,stroke:#1565c0,stroke-width:1px
```

## Self-Service Project Request Flow

```mermaid
sequenceDiagram
    actor Team as App Team
    participant Repo as Git Repository
    actor Platform as Platform Team
    participant CI as CI/CD Pipeline
    participant TF as Terraform
    participant STACKIT as STACKIT API

    Team->>Repo: 1. Submit YAML request via PR
    Note right of Team: project_name, team, environment,<br/>members, firewall_rules

    Repo->>Platform: 2. PR triggers review
    Platform->>Platform: 3. Review: IAM, firewall rules,<br/>cost center, environment

    Platform->>Repo: 4. Approve & merge PR

    Repo->>CI: 5. Merge triggers pipeline
    CI->>TF: 6. terraform plan + apply<br/>(03-projects layer)

    TF->>STACKIT: Create project (attached to env SNA)
    TF->>STACKIT: Create routed network
    TF->>STACKIT: Create security groups (spoke-only ingress)
    TF->>STACKIT: Create custom RBAC role
    TF->>STACKIT: Assign team member roles
    TF->>STACKIT: Create delegated DNS zone
    TF->>STACKIT: Create firewall rules (if any)

    STACKIT-->>Team: 7. Project ready to use!
    Note right of Team: Team deploys workloads<br/>within guardrails
```

## Deployment Layers

```mermaid
graph TB
    subgraph L0["Layer 0: Bootstrap"]
        direction LR
        l0_desc["S3 state + audit buckets"]
        l0_state["State: local"]
    end

    subgraph L1["Layer 1: Hub"]
        direction LR
        l1_desc["Project, DNS root zone,<br/>Service accounts, Folder IAM"]
        l1_state["State: s3://hub/"]
    end

    subgraph L2["Layer 2: Spokes (per env)"]
        direction LR
        l2_desc["SNA, Spoke project, Network, SGs,<br/>DNS sub-zone (NS delegation from hub),<br/>Bastion, Observability"]
        l2_state["State: s3://spokes/&lt;env&gt;/"]
    end

    subgraph L3["Layer 3: Projects (self-service)"]
        direction LR
        l3_desc["Team projects from YAML requests<br/>via project-factory module"]
        l3_state["State: s3://projects/"]
    end

    L0 -->|"creates state backend"| L1
    L1 -->|"remote_state: folder IDs,<br/>SA emails, DNS root zone ID"| L2
    L2 -->|"remote_state: SNA ID,<br/>spoke prefix, DNS zone"| L3

    style L0 fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    style L1 fill:#fff3e0,stroke:#e65100,stroke-width:2px
    style L2 fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    style L3 fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
```

## Example: Development Workload (SKE Kubernetes)

```mermaid
graph TB
    subgraph sna["SNA: dev-sna (10.0.0.0/16)"]
        direction TB

        subgraph spoke["Spoke: dev"]
            bastion_h["Bastion"]
            prom_h["Observability<br/><i>Prometheus + Grafana</i>"]
        end

        subgraph project["team-alpha-dev &mdash; provisioned by landing zone"]
            direction TB

            subgraph guardrails["Landing Zone Guardrails"]
                net["Routed Network (SNA)<br/><i>Private connectivity within dev env</i>"]
                sg["Security Groups<br/><i>Ingress: Spoke prefix only (:443, :22)</i><br/><i>Egress: All allowed</i>"]
                rbac["Custom RBAC: team-editor<br/><i>No public IPs, no SG changes, no IAM escalation</i>"]
                dns_zone["DNS: team-alpha-dev.dev.example.com<br/><i>Team manages own records via portal</i>"]
            end

            subgraph workload["Team-Deployed Workload"]
                direction TB
                cluster["SKE Cluster"]
                subgraph nodes["Node Pools"]
                    app_pool["app-pool: 3x g2i.2"]
                    infra_pool["infra-pool: 2x g2i.4"]
                end
                subgraph pods["Kubernetes Workloads"]
                    frontend["frontend<br/>Deployment :443"]
                    backend["backend<br/>Deployment :8080"]
                    worker["batch-worker<br/>CronJob"]
                    postgres["PostgreSQL<br/>StatefulSet :5432"]
                end
                cluster --> nodes --> pods
            end
        end
    end

    bastion_h -->|"SSH via private IP"| net
    prom_h -->|"Scrape metrics<br/>via SNA"| net

    style sna fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    style spoke fill:#fff3e0,stroke:#e65100,stroke-width:2px
    style project fill:#e3f2fd,stroke:#1565c0,stroke-width:1px
    style guardrails fill:#e8f5e9,stroke:#2e7d32,stroke-width:1px
    style workload fill:#fff8e1,stroke:#f9a825,stroke-width:1px
    style nodes fill:#f5f5f5,stroke:#9e9e9e,stroke-width:1px
    style pods fill:#f5f5f5,stroke:#9e9e9e,stroke-width:1px
```

## Example: Production Workload (IaaS VMs)

```mermaid
graph TB
    subgraph sna["SNA: prod-sna (10.2.0.0/16)"]
        direction TB

        subgraph spoke["Spoke: prod"]
            bastion_h["Bastion"]
            prom_h["Observability<br/><i>Prometheus + Grafana</i>"]
        end

        subgraph project["team-alpha-prod &mdash; provisioned by landing zone"]
            direction TB

            subgraph guardrails["Landing Zone Guardrails"]
                net["Routed Network (SNA)<br/><i>Private connectivity within prod env</i>"]
                sg["Security Groups<br/><i>Ingress: Spoke prefix only (:443, :22)</i><br/><i>Egress: All allowed</i>"]
                rbac["Custom RBAC<br/><i>alpha-dev1: reader (prod = read-only)</i><br/><i>alpha-lead: owner</i>"]
                dns_zone["DNS: team-alpha-prod.prod.example.com<br/><i>Team manages own records via portal</i>"]
            end

            subgraph workload["Team-Deployed Workload"]
                direction TB
                subgraph app_tier["Application Tier"]
                    vm1["VM: app-01<br/><i>nginx + app server</i><br/>:443 :8080"]
                    vm2["VM: app-02<br/><i>nginx + app server</i><br/>:443 :8080"]
                end
                subgraph data_tier["Data Tier"]
                    db["VM: db-01<br/><i>PostgreSQL</i><br/>:5432"]
                end
                vm1 & vm2 -->|":5432"| db
            end

            subgraph fw_rules["Firewall Rules (PR-approved)"]
                fw1["allow-monitoring: tcp :9100<br/><i>from spoke prefix</i>"]
            end
        end
    end

    bastion_h -->|"SSH via private IP"| net
    prom_h -->|"Scrape :9100<br/>via SNA"| fw1

    style sna fill:#fce4ec,stroke:#c62828,stroke-width:2px
    style spoke fill:#fff3e0,stroke:#e65100,stroke-width:2px
    style project fill:#fce4ec,stroke:#c62828,stroke-width:1px
    style guardrails fill:#e8f5e9,stroke:#2e7d32,stroke-width:1px
    style workload fill:#fff8e1,stroke:#f9a825,stroke-width:1px
    style fw_rules fill:#ffebee,stroke:#d32f2f,stroke-width:1px
    style app_tier fill:#f5f5f5,stroke:#9e9e9e,stroke-width:1px
    style data_tier fill:#f5f5f5,stroke:#9e9e9e,stroke-width:1px
```

## IP Allocation & Network Capacity

### Per-Environment SNA IP Ranges

Each environment gets its own SNA with a dedicated `/16` IP pool:

| Environment | SNA Name | Network Range | Transfer Network |
|-------------|----------|---------------|------------------|
| dev | `dev-sna` | `10.0.0.0/16` | `10.255.0.0/24` |
| staging | `staging-sna` | `10.1.0.0/16` | `10.255.1.0/24` |
| prod | `prod-sna` | `10.2.0.0/16` | `10.255.2.0/24` |

### How SNA Assigns Subnets

When a project with the `networkArea` label creates a `routed = true` network, the SNA automatically allocates the **next available /24** from the pool — you cannot choose a specific subnet.

```mermaid
graph TB
    subgraph dev_pool["dev-sna: 10.0.0.0/16"]
        direction TB
        subgraph dev_alloc["Allocated"]
            direction LR
            d0["10.0.0.0/24<br/><b>spoke-dev</b>"]
            d1["10.0.1.0/24<br/><b>team-alpha-dev</b>"]
            d2["10.0.2.0/24<br/><b>team-beta-dev</b>"]
        end
        dev_free["10.0.3.0/24 &mdash; 10.0.254.0/24<br/><i>~253 available</i>"]
    end

    subgraph prod_pool["prod-sna: 10.2.0.0/16"]
        direction TB
        subgraph prod_alloc["Allocated"]
            direction LR
            p0["10.2.0.0/24<br/><b>spoke-prod</b>"]
            p1["10.2.1.0/24<br/><b>team-alpha-prod</b>"]
        end
        prod_free["10.2.2.0/24 &mdash; 10.2.254.0/24<br/><i>~254 available</i>"]
    end

    style dev_pool fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    style prod_pool fill:#fce4ec,stroke:#c62828,stroke-width:2px
    style dev_alloc fill:#fff3e0,stroke:#e65100,stroke-width:1px
    style prod_alloc fill:#fff3e0,stroke:#e65100,stroke-width:1px
```

### Capacity Limits (per environment)

| Resource | Limit | Notes |
|----------|-------|-------|
| Total /24 subnets per env | **255** | 10.x.0.0/24 through 10.x.254.0/24 |
| Reserved for spoke | **1** | Spoke project network |
| Available for team projects | **~254** | Each routed network consumes 1 subnet |
| Usable IPs per subnet | **~251** | 5 reserved by STACKIT (gateway, broadcast, etc.) |
| VMs/interfaces per subnet | **~251** | 1 private IP per network interface |
| **Total across 3 envs** | **~762 team projects** | 254 per env x 3 environments |

### Scaling Options

| Strategy | Change | Result |
|----------|--------|--------|
| **Add ranges** | Add `{prefix="10.0.0.0/16"}, {prefix="10.3.0.0/16"}` to dev SNA | +255 subnets for dev |
| **Use /25 subnets** | `sna_default_prefix_length = 25` | 510 subnets per env, 126 IPs each |
| **Use /23 subnets** | `sna_default_prefix_length = 23` | 127 subnets per env, 510 IPs each |

### Important Constraints

- **One SNA per project** — a project can only attach to one network area (single `networkArea` label)
- **Fixed subnet size** — all networks in an SNA get the same prefix length; you cannot mix /23 and /24
- **No subnet selection** — STACKIT assigns the next available block automatically
- **Transfer network reserved** — must not overlap with network ranges
- **No cross-environment routing** — separate SNAs have no routing path between them (this is the desired isolation)

## Key Benefits

```mermaid
mindmap
    root((STACKIT<br/>Landing Zone))
        Governance
            GitOps-driven project provisioning
            PR-based approval for access & firewall
            Full audit trail in git history
            Centralized cost tracking via labels
        Security
            L3 network isolation between environments
            Per-environment SNA prevents cross-stage access
            Custom RBAC prevents privilege escalation
            No public IPs for team workloads
            Teams cannot modify firewall rules
        Self-Service
            Teams request projects via YAML + PR
            Delegated DNS zones per project
            Deploy any workload: SKE, VMs, managed DBs
            Within guardrails set by platform team
        Automation
            4-layer Terraform architecture
            Reusable modules for consistency
            CI/CD service account with folder-level access
            Cross-layer remote state — no manual ID passing
            Per-environment Prometheus + Grafana
        Sovereign Cloud
            STACKIT: EU data sovereignty
            No hyperscaler dependency
            GDPR-compliant by design
            German/EU data centers only
```

## YAML Request Example

```yaml
# 03-projects/requests/team-alpha-dev.yaml
project_name: "team-alpha-dev"
team: "alpha"
environment: "dev"
owner_email: "alpha-lead@company.com"

members:
  - email: "alpha-dev1@company.com"
    role: "editor"        # mapped to restricted "team-editor"
  - email: "alpha-dev2@company.com"
    role: "editor"

extra_labels:
  cost_center: "cc-1234"
  application: "webshop"

# Cross-project access within same environment (requires platform team PR approval)
# firewall_rules:
#   - name: "allow-beta-api"
#     protocol: "tcp"
#     ip_range: "10.0.2.0/24"
#     port_min: 8080
#     port_max: 8080
```
