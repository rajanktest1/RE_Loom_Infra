# InfraRepo - Real Estate Platform Infrastructure

Infrastructure as Code (IaC) for the Real Estate microservices platform deployed on Azure.

## Architecture

```
Azure Cloud
├── AKS (Kubernetes)
│   ├── Gateway (NGINX Ingress → Express)
│   ├── Auth Service
│   ├── Inventory Service
│   ├── Supply Chain Service
│   ├── CRM Service
│   ├── Notification Service
│   ├── Document Service
│   ├── Web (React SPA on NGINX)
│   └── RabbitMQ (StatefulSet)
├── CosmosDB (MongoDB API)
├── Azure Cache for Redis
├── Azure Blob Storage
├── Azure Key Vault
├── Azure Container Registry
└── Log Analytics / Container Insights
```

## Repository Structure

```
InfraRepo/
├── terraform/
│   ├── state-backend/          # Bootstrap: state storage account
│   ├── modules/
│   │   ├── networking/         # VNet, Subnets, NSGs
│   │   ├── aks/                # AKS cluster
│   │   ├── acr/                # Container Registry
│   │   ├── cosmosdb/           # CosmosDB (Mongo API)
│   │   ├── redis/              # Azure Cache for Redis
│   │   ├── storage/            # Blob Storage
│   │   ├── keyvault/           # Key Vault + secrets
│   │   └── monitoring/         # Log Analytics
│   └── environments/
│       ├── dev/
│       ├── staging/
│       └── prod/
├── k8s/
│   ├── base/                   # Kustomize base manifests
│   │   ├── deployments/        # 8 service deployments
│   │   ├── services/           # ClusterIP services
│   │   ├── ingress.yaml        # NGINX Ingress rules
│   │   ├── hpa.yaml            # Autoscaling
│   │   └── ...
│   └── overlays/
│       ├── dev/
│       ├── staging/
│       └── prod/
├── .github/workflows/
│   ├── terraform-plan.yml      # PR: plan all envs
│   ├── terraform-apply.yml     # Push/manual: apply
│   └── deploy-app.yml          # Deploy images to AKS
└── scripts/
    ├── bootstrap-state.sh      # Create state storage
    └── setup-github-oidc.sh    # OIDC federation setup
```

## Quick Start

### Prerequisites

- Azure CLI (`az`) logged in
- Terraform >= 1.7.0
- kubectl
- kustomize

### 1. Bootstrap State Backend

```bash
chmod +x scripts/bootstrap-state.sh
./scripts/bootstrap-state.sh
```

Save the output storage account name for use in backend configs.

### 2. Setup OIDC Federation

```bash
chmod +x scripts/setup-github-oidc.sh
./scripts/setup-github-oidc.sh <your-github-username-or-org>
```

Add the output secrets to both GitHub repositories.

### 3. Configure GitHub Secrets

**Both repos** need:
| Secret | Description |
|--------|-------------|
| `AZURE_CLIENT_ID` | App Registration Client ID |
| `AZURE_TENANT_ID` | Azure AD Tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Target subscription |

**InfraRepo** additionally needs:
| Secret | Description |
|--------|-------------|
| `TF_STATE_STORAGE_ACCOUNT` | From bootstrap output |

**AppRepo** additionally needs:
| Variable | Description |
|----------|-------------|
| `ACR_NAME` | ACR name (from Terraform output) |
| `VITE_API_URL` | API base URL for frontend |

**AppRepo** secret:
| Secret | Description |
|--------|-------------|
| `INFRA_REPO_PAT` | PAT with repo dispatch permission |

### 4. Deploy Infrastructure

```bash
cd terraform/environments/dev
terraform init -backend-config="storage_account_name=<YOUR_STORAGE_ACCOUNT>"
terraform plan
terraform apply
```

### 5. Deploy Application

After infrastructure is provisioned:
1. Push code to AppRepo `main` branch
2. CI builds images → pushes to ACR
3. Triggers `deploy-app` workflow in InfraRepo
4. Kustomize deploys to AKS

## Environments

| Environment | AKS Nodes | Redis | Purpose |
|-------------|-----------|-------|---------|
| dev | B2ms (1-3) | Basic C0 | Development/testing |
| staging | B4ms (2-5) | Standard C1 | Pre-production |
| prod | D4s_v3 (3-10) | Premium P1 | Production |

## CI/CD Flow

```
AppRepo (push to main)
  → Build & push 8 Docker images to ACR
  → repository_dispatch to InfraRepo
    → deploy-app.yml
      → kubectl apply -k k8s/overlays/<env>
```

```
InfraRepo (push to main, terraform/ changed)
  → terraform apply (dev auto, staging/prod manual)
```

## Manual Deployment

```bash
# Deploy specific tag to an environment
gh workflow run deploy-app.yml \
  -f image_tag=sha-abc1234 \
  -f environment=staging
```
