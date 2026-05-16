# Opella Azure Infrastructure — Terraform

Provisions Azure infrastructure across **dev** and **prod** environments using a reusable Terraform VNET module.

## Architecture

```
infra/
├── modules/
│   └── vnet/               # Reusable VNET module
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
├── environments/
│   ├── dev/                # East US — Standard_B1s VM, LRS storage
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   └── prod/               # West Europe — Standard_B2s VM, GRS storage
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars
├── .github/
│   └── workflows/
│       ├── terraform-dev.yml
│       └── terraform-prod.yml
├── .tflint.hcl
└── .gitignore
```

## Resources per environment

| Resource | Dev | Prod |
|----------|-----|------|
| Resource Group | `rg-opella-dev-eastus` | `rg-opella-prod-westeurope` |
| VNet (module) | `10.10.0.0/16` | `10.20.0.0/16` |
| Subnets | `snet-web-dev`, `snet-app-dev` | `snet-web-prod`, `snet-app-prod` |
| NSG per subnet | ✅ | ✅ |
| Storage Account | Standard LRS | Standard GRS |
| Blob Container | `data` (private) | `data` (private) |
| Linux VM | `Standard_B1s` (Ubuntu 22.04) | `Standard_B2s` (Ubuntu 22.04) |

## Why Resource Groups (not Subscriptions) per environment?

For this challenge's scope (free tier, single developer), Resource Groups provide sufficient isolation:
- **Cost**: No extra subscription overhead.
- **RBAC**: You can still scope IAM roles to a Resource Group.
- **Naming**: Env + region encoded in every resource name makes ownership obvious.

Use separate Subscriptions when you need billing isolation, subscription-level policy enforcement, or hard quota boundaries — typically at team/product scale.

## Tagging strategy

Every resource gets four mandatory tags enforced via the `locals` block in each environment:

| Tag | Value | Purpose |
|-----|-------|---------|
| `Environment` | `dev` / `prod` | Cost allocation, policy targeting |
| `Region` | `eastus` / `westeurope` | Quick visual identification |
| `ManagedBy` | `Terraform` | Flags resources as IaC-managed |
| `Project` | `opella` | Cross-environment grouping |

To enforce tagging across the org, attach an **Azure Policy** (`Require a tag and its value on resources`) scoped to the subscription.

## How to run locally

### Prerequisites

- [Terraform ≥ 1.5](https://developer.hashicorp.com/terraform/install)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- An SSH key pair (`ssh-keygen -t rsa -b 4096`)

### Steps

```bash
# 1. Authenticate
az login

# 2. Set SSH public key
export TF_VAR_vm_public_key="$(cat ~/.ssh/id_rsa.pub)"

# 3. Init and plan dev
cd environments/dev
terraform init
terraform plan

# 4. Apply dev
terraform apply
```

## GitHub Actions — Release lifecycle

```
feature-branch  ──PR──►  main
                           │
               ┌───────────┼────────────────┐
               ▼           ▼                ▼
          fmt-check    validate         tflint
               └───────────┼────────────────┘
                           ▼
                       plan (posted as PR comment)
                           │
                    merge to main
                           │
               ┌───────────┴────────────┐
               ▼                        ▼
          apply dev              plan prod (preview)
                                         │
                                  manual approval
                                         │
                                   apply prod
```

### Required GitHub Secrets

Set these in **Settings → Secrets and variables → Actions**:

| Secret | Description |
|--------|-------------|
| `ARM_SUBSCRIPTION_ID` | Azure Subscription ID |
| `ARM_TENANT_ID` | Azure Tenant ID |
| `ARM_CLIENT_ID` | Service Principal Client ID |
| `ARM_CLIENT_SECRET` | Service Principal Client Secret |
| `TF_VAR_VM_PUBLIC_KEY` | SSH public key for VM admin |

### Creating the Service Principal

```bash
az ad sp create-for-rbac \
  --name "sp-opella-terraform" \
  --role "Contributor" \
  --scopes "/subscriptions/<SUBSCRIPTION_ID>"
```

## Code quality tools

| Tool | Purpose | How to run |
|------|---------|-----------|
| `terraform fmt` | Canonical formatting | `terraform fmt -recursive` |
| `terraform validate` | Config validity | `terraform validate` |
| `tflint` | Linting + Azure rules | `tflint --recursive` |
| `terraform-docs` | Auto-generate module docs | `terraform-docs markdown modules/vnet > modules/vnet/README.md` |

Install terraform-docs: `choco install terraform-docs` or `brew install terraform-docs`
