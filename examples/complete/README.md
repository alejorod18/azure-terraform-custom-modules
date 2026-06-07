# Ejemplo Completo: Stack de Infraestructura Azure Multi-Módulo

Este ejemplo demuestra cómo utilizar múltiples módulos en conjunto para provisionar un stack de aplicación listo para producción en Azure.

## Qué Crea este Ejemplo

| Recurso | Módulo Utilizado | Propósito |
|---------|------------------|-----------|
| Subnet (App Services) | `module-networks-infrastructure` | Subnet dedicada para la integración de App Service a la VNet |
| Subnet (Private Endpoints) | `module-networks-infrastructure` | Subnet aislada para conexiones de endpoints privados |
| Storage Account | `module-storage-infrastructure` | Almacenamiento de blobs con private endpoint |
| Key Vault | `module-secrets-infrastructure` | Gestión centralizada de secretos |
| Cosmos DB | `module-cosmos-infrastructure` | Base de datos NoSQL con private endpoint |
| Event Hub | `module-events-hubs-infrastructure` | Plataforma de streaming de eventos |
| App Service Plan + Web Apps | `module-appservices-infrastructure` | Aplicaciones web integradas con Key Vault |
| Private Endpoints | `module-private-endpoints-infrastructure` | Conectividad segura hacia servicios de datos |

## Diagrama de Arquitectura

```mermaid
flowchart TB
    subgraph RG["Resource Group: rg-example-dev"]
        subgraph VNET["Virtual Network: vnet-example-dev"]
            SUB_APP["snet-appservice<br/>10.0.1.0/24"]
            SUB_PE["snet-privateendpoints<br/>10.0.2.0/24"]
        end

        ASP["App Service Plan<br/>P1v2"]
        WEB1["Web App: api"]
        WEB2["Web App: admin"]

        KV["Key Vault"]
        ST["Storage Account"]
        COSMOS["Cosmos DB"]
        EH["Event Hub Namespace"]

        PE_KV["PE → Key Vault"]
        PE_ST["PE → Storage"]
        PE_COSMOS["PE → Cosmos DB"]
    end

    SUB_APP --> ASP
    ASP --> WEB1
    ASP --> WEB2

    SUB_PE --> PE_KV
    SUB_PE --> PE_ST
    SUB_PE --> PE_COSMOS

    PE_KV -.-> KV
    PE_ST -.-> ST
    PE_COSMOS -.-> COSMOS

    WEB1 -- "Referencias Key Vault" --> KV
    WEB2 -- "Referencias Key Vault" --> KV
```

## Requisitos Previos

1. Un Resource Group de Azure existente
2. Una Virtual Network de Azure existente
3. Un Log Analytics Workspace
4. Azure CLI autenticado: `az login`

## Uso

```bash
# Copia las variables de ejemplo
cp terraform.tfvars.example terraform.tfvars

# Edita el archivo con tus propios valores
vim terraform.tfvars

# Despliega
terraform init
terraform plan
terraform apply
```

## Limpieza

```bash
terraform destroy
```
