# Terraform Module: Azure MSSQL Server with Geo-Replication and Failover

This Terraform module provisions an **Azure MSSQL Server** infrastructure with enterprise-grade features:

---

## Features

- **Primary + Secondary Servers**: Geo-replicated SQL Server instances for disaster recovery
- **Failover Group**: Automatic failover configuration with read/write endpoint policies
- **Threat Detection**: Advanced threat protection with email alerts and audit logging
- **Backup Policies**: Long-term and short-term retention with configurable intervals
- **Firewall Rules**: IP-based whitelisting with CIDR support
- **Private Endpoints**: Secure private connectivity via Azure Private Link
- **Diagnostics**: Integration with Azure Monitor and Log Analytics
- **Security**: Random password generation for admin credentials, AAD integration, TLS 1.2 minimum

---


## 🏗 Arquitectura del Módulo

```mermaid
graph TD
    subgraph Azure["Azure Cloud"]
        Resource["⚡ Sqlserver"]
        PE["🔒 Private Endpoint"]
        DNS["🌐 Private DNS Zone"]
        Log["📊 Log Analytics Workspace"]
    end
    
    Resource -->|Diagnostics| Log
    Resource --- PE
    PE --- DNS
    
    style Azure fill:#1a1a2e,stroke:#e94560,color:#fff
    style Resource fill:#0f3460,stroke:#58a6ff,color:#fff
    style PE fill:#16c79a,stroke:#fff,color:#000
    style DNS fill:#16c79a,stroke:#fff,color:#000
    style Log fill:#f9d923,stroke:#fff,color:#000
```

## 🔄 Flujo de Uso

```mermaid
sequenceDiagram
    participant User as Usuario / CI/CD
    participant TF as Terraform
    participant Azure as Azure API
    participant Res as Sqlserver
    
    User->>TF: terraform apply
    TF->>Azure: Autenticación & Llamadas API
    Azure->>Res: Provisionar Recursos
    Azure->>Res: Configurar RBAC y Endpoints
    Res-->>TF: Estado actualizado
    TF-->>User: Despliegue completado
```

## Requirements

| Name | Version |
|------|---------|
| Terraform | `>= 1.0.0` |
| azurerm | `~> 4.16` |
| http | `~> 3.0` |

---

## Usage

### Basic Example

```hcl
module "sqlserver" {
  source = "git::https://github.com/<your-org>/azure-terraform-custom-modules.git//module-sqlserver-infrastructure"

  resource_group_name        = "rg-myapp-dev"
  identifier                 = "myapp"
  log_analytics_workspace_id = "<log-analytics-workspace-id>"

  ip_range_whitelist = ["203.0.113.0/24"]

  private_endpoints = {
    "sqlserver" = {
      subnet_id             = "<private-endpoint-subnet-id>"
      private_dns_zone_name = "privatelink.database.windows.net"
      subresource_name      = "sqlServer"
    }
  }
}
```

---

## Variables

| Variable | Type | Description | Required |
|----------|------|-------------|----------|
| `resource_group_name` | `string` | Name of the Azure Resource Group | Yes |
| `identifier` | `string` | Unique identifier for naming resources | Yes |
| `ip_range_whitelist` | `list(string)` | List of IP addresses/CIDRs allowed to access the server | No |
| `log_analytics_workspace_id` | `string` | Log Analytics Workspace ID for diagnostics | No |
| `private_endpoints` | `map(object)` | Private endpoint configurations | No |
| `passwords_length` | `number` | Length of generated passwords | No |
| `passwords_special_characters` | `string` | Allowed special characters in generated passwords | No |

---

## Outputs

| Output | Description | Sensitive |
|--------|-------------|-----------|
| `servers_fqdn` | The FQDN of the primary SQL Server | Yes |
| `administrator_login_password` | The admin login password | Yes |
| `users_credentials` | Map of user credentials | Yes |

---

## Architecture

```mermaid
flowchart LR
    subgraph Primary["Primary Region"]
        SRV1["MSSQL Server<br/>(Primary)"]
        DB1["Database"]
    end

    subgraph Secondary["Secondary Region (DR)"]
        SRV2["MSSQL Server<br/>(Secondary)"]
        DB2["Database<br/>(Geo-replica)"]
    end

    FG["Failover Group"]

    SRV1 --> DB1
    SRV2 --> DB2
    FG --> SRV1
    FG --> SRV2
    DB1 -.->|"Geo-Replication"| DB2

    style Primary fill:#1a1a2e,stroke:#16c79a,color:#fff
    style Secondary fill:#1a1a2e,stroke:#e94560,color:#fff
```

---

## Notes

- This module uses `lifecycle { prevent_destroy = true }` on servers and databases to prevent accidental deletion in production.
- Admin passwords are generated using `random_password` — never hardcoded.
- The failover group is configured in `Manual` mode by default for controlled failover scenarios.
