# Opella DevOps Challenge — Azure Infrastructure with Terraform

This project provisions cloud infrastructure on Microsoft Azure using Terraform.
It creates two separate environments (dev and prod) using a single reusable
building block called a Terraform module.

---

## What does this project do?

Every time code is pushed to GitHub, an automated pipeline:

1. Checks that the code is clean and correctly formatted
2. Connects to Azure securely (no passwords stored — uses OIDC tokens)
3. Shows a preview of what will change in Azure (terraform plan)
4. Can optionally apply those changes (currently commented out for safety)

It builds the following Azure resources in **both dev and prod**:

| Resource | What it is |
|----------|-----------|
| Resource Group | A folder in Azure that holds all our resources |
| Virtual Network | A private network in Azure (like a LAN in the cloud) |
| Subnets | Smaller segments inside the VNet (web layer, app layer) |
| Network Security Groups | Firewall rules controlling allowed traffic |
| Linux Virtual Machine | A small Ubuntu server running in the cloud |
| Storage Account | Cloud storage (like a shared drive) |
| Blob Container | A private bucket inside storage for files/data |

---

## Folder Structure

```
opella-challenge/
│
├── modules/
│   └── vnet/               <-- Reusable building block for Virtual Networks
│       ├── main.tf         <-- Actual Azure resources (VNet, subnets, NSGs)
│       ├── variables.tf    <-- Inputs the module accepts
│       ├── outputs.tf      <-- What the module gives back (IDs, names)
│       └── README.md       <-- Module documentation
│
├── environments/
│   ├── dev/                <-- Development environment (East US region)
│   │   ├── main.tf         <-- Calls the VNet module + creates VM and storage
│   │   ├── variables.tf    <-- All configurable values for dev
│   │   ├── outputs.tf      <-- Useful values printed after deployment
│   │   └── terraform.tfvars  <-- Actual values used for dev
│   │
│   └── prod/               <-- Production environment (West Europe region)
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars
│
├── .github/
│   └── workflows/
│       ├── opella-terraform-dev.yml   <-- CI/CD pipeline for dev
│       └── opella-terraform-prod.yml  <-- CI/CD pipeline for prod
│
├── .tflint.hcl             <-- Linting rules to catch mistakes early
├── .gitignore              <-- Files never committed (state files, secrets)
└── README.md               <-- Module-level docs
```

---

## Dev vs Prod — What is different?

| Setting | Dev | Prod |
|---------|-----|------|
| Azure Region | East US | West Europe |
| Network range | 10.10.0.0/16 | 10.20.0.0/16 (separate, non-overlapping) |
| VM Size | Standard_B1s (1 CPU, 1 GB RAM) | Standard_B2s (2 CPU, 4 GB RAM) |
| Storage redundancy | LRS — 1 copy, cheapest | GRS — 6 copies across 2 regions |
| HTTP access | Allowed (easier for dev testing) | Blocked (HTTPS only in prod) |

---

## Why Resource Groups and not separate Subscriptions?

Both environments live in the **same Azure subscription** but in separate Resource Groups (RGs).

- **Resource Groups** are free, simple to manage, and give enough isolation for a small team
- **Subscriptions** make sense when you need separate billing, strict quota limits, or compliance boundaries between large teams

> Rule of thumb: Resource Groups for projects and small teams. Subscriptions for large enterprises with multiple independent teams.

---

## How does the reusable module work?

The `modules/vnet/` folder is like a template. Instead of copy-pasting the same
networking code for dev and prod, both environments call the same module with
different settings:

```hcl
# Dev calls the module like this:
module "vnet" {
  source        = "../../modules/vnet"
  vnet_name     = "vnet-opella-dev-eastus"
  address_space = ["10.10.0.0/16"]
  ...
}

# Prod calls the exact same module with different values:
module "vnet" {
  source        = "../../modules/vnet"
  vnet_name     = "vnet-opella-prod-westeurope"
  address_space = ["10.20.0.0/16"]
  ...
}
```

Any improvement to the module automatically benefits both environments.

---

## How is tagging enforced?

Every Azure resource automatically gets these 4 tags:

| Tag | Example Value | Why it matters |
|-----|--------------|----------------|
| `Environment` | dev / prod | Know which environment a resource belongs to |
| `Region` | eastus / westeurope | Know where the resource lives |
| `ManagedBy` | Terraform | Know this was created by code, not manually |
| `Project` | opella | Group all resources for this project together |

Tags are defined once in a `locals` block and applied to every resource —
you cannot forget to tag something because it is automatic.

To enforce tagging at the organisation level, attach an **Azure Policy**
(`Require a tag and its value`) scoped to the subscription.

---

## How does the CI/CD pipeline work?

```
You push code to GitHub
        │
        ▼
  Format Check   — Is the code properly formatted? (terraform fmt)
        │
        ▼
  Init           — Download providers, connect to remote state storage
        │
        ▼
  Validate       — Is the Terraform code valid? (no syntax errors)
        │
        ▼
  Plan           — Show what WOULD change in Azure (nothing is touched yet)
        │
        ├── On a Pull Request → plan is posted as a comment on the PR
        │
        └── On merge to main → plan is saved as an artifact

  Apply is currently commented out in the workflow files.
  Uncomment it when you are ready to deploy automatically.
```

---

## How is Azure authentication handled? (No passwords stored!)

This project uses **OIDC (OpenID Connect)** — a modern passwordless authentication method.

Instead of storing a password, GitHub gets a short-lived token from Azure that
expires after a few minutes. Azure only trusts tokens coming from this specific
GitHub repository.

Three trust relationships are registered in Azure AD:

| Credential Name | Used when |
|-----------------|-----------|
| `github-main` | Plan jobs run (on push to main branch) |
| `github-env-dev` | Apply job runs for dev environment |
| `github-env-prod` | Apply job runs for prod environment |

---

## Where is Terraform state stored?

Terraform keeps a record of everything it has built (called a state file).
This is stored in an Azure Blob Storage account so that:

- The state is never lost if your laptop breaks
- Multiple people can work on the same infrastructure safely
- Dev and prod have completely separate state files

| Environment | State file |
|-------------|-----------|
| Dev | `opella-dev.terraform.tfstate` |
| Prod | `opella-prod.terraform.tfstate` |

---

## How to run this on your local machine

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) v1.5 or newer
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- An SSH key pair — generate one with: `ssh-keygen -t rsa -b 4096`

### Steps

```bash
# 1. Log in to Azure
az login

# 2. Go to the dev environment folder
cd opella-challenge/environments/dev

# 3. Provide your SSH public key for the VM
export TF_VAR_vm_public_key="$(cat ~/.ssh/id_rsa.pub)"

# 4. Download providers and connect to remote state
terraform init

# 5. Preview what will be created (nothing changes yet)
terraform plan

# 6. Actually create the resources in Azure
terraform apply
```

---

## Code quality tools

| Tool | What it does | How to run |
|------|-------------|-----------|
| `terraform fmt` | Formats code consistently | `terraform fmt -recursive` |
| `terraform validate` | Checks for syntax errors | `terraform validate` |
| `tflint` | Catches Azure-specific mistakes | `tflint --recursive` |
| `terraform-docs` | Auto-generates docs from code | see below |

To auto-generate module documentation:
```bash
# Install terraform-docs first:
# Windows: choco install terraform-docs
# Mac:     brew install terraform-docs

terraform-docs markdown opella-challenge/modules/vnet > opella-challenge/modules/vnet/README.md
```

---

## Terraform Plan Output

The full plan output is saved in `opella-challenge/terraform-plan-dev.txt`.

It shows **14 resources to add, 0 to change, 0 to destroy** for the dev environment.
