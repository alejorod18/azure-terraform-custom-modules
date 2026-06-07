
# Explicación del Código del Módulo: Azure Private Endpoint con Configuración DNS

Este módulo de Terraform implementa un **Azure Private Endpoint** con configuración de DNS privada. A continuación, se describe cómo está estructurado el código y qué hace cada componente.

---

## Estructura del Módulo

El módulo se compone de varios archivos que definen sus características principales:

1. **`main.tf`**:
   - Define los recursos principales del módulo.
   - Contiene la lógica para crear:
     - Zona DNS Privada (`azurerm_private_dns_zone`).
     - Vinculación de la Zona DNS Privada a la red virtual (`azurerm_private_dns_zone_virtual_network_link`).
     - Endpoint Privado (`azurerm_private_endpoint`).

2. **`variables.tf`**:
   - Define las variables de entrada necesarias para el módulo.
   - Incluye validaciones detalladas para asegurar que los valores proporcionados cumplan con los formatos esperados.

3. **`data.tf`**:
   - Obtiene información sobre los recursos existentes utilizando bloques de datos (`data`).
   - Por ejemplo, recupera detalles del grupo de recursos asociado a los IDs proporcionados.

4. **`versions.tf`**:
   - Establece las versiones requeridas de Terraform y los providers necesarios, en este caso, `azurerm`.

5. **`README.md`**:
   - Proporciona una guía de uso para los usuarios finales del módulo.

---

## Descripción de las Funcionalidades

### 1. Creación de Recursos

#### Zona DNS Privada
El módulo puede crear una zona DNS privada nueva si no se proporciona una existente. Este recurso es crucial para habilitar resoluciones de DNS privadas dentro de la red.

```hcl
resource "azurerm_private_dns_zone" "dns" {
  count               = !local.existing_private_ds_zone ? 1 : 0
  name                = var.private_dns_zone_name
  resource_group_name = data.azurerm_resource_group.resource.name
  tags                = data.azurerm_resource_group.resource.tags
}
```

#### Vinculación de la Zona DNS Privada a la Red Virtual
Este recurso vincula la zona DNS privada con una red virtual específica para permitir la resolución de nombres dentro de la red.

```hcl
resource "azurerm_private_dns_zone_virtual_network_link" "dns" {
  count                 = !local.existing_private_ds_zone ? 1 : 0
  name                  = "${var.identifier}-dns"
  private_dns_zone_name = local.private_dns_name
  virtual_network_id    = local.vnet_id
  resource_group_name   = data.azurerm_resource_group.resource.name
  tags                  = data.azurerm_resource_group.resource.tags
}
```

#### Endpoint Privado
El módulo crea un endpoint privado que conecta de manera segura un recurso específico dentro de Azure.

```hcl
resource "azurerm_private_endpoint" "pe" {
  location            = data.azurerm_resource_group.resource.location
  name                = "pe-${var.identifier}"
  resource_group_name = data.azurerm_resource_group.resource.name
  subnet_id           = var.subnet_id
  tags                = data.azurerm_resource_group.resource.tags

  private_dns_zone_group {
    name = "${var.identifier}-dns-zone-group"
    private_dns_zone_ids = [
      local.private_dns_id
    ]
  }

  private_service_connection {
    name                           = "${var.identifier}-private-service-connection"
    is_manual_connection           = false
    private_connection_resource_id = var.resource_id
    subresource_names              = [var.subresource_name]
  }
}
```

### 2. Manejo de Variables Locales
El módulo utiliza variables locales (`locals`) para simplificar las referencias a elementos complejos, como IDs de recursos y nombres generados dinámicamente.

```hcl
locals {
  existing_private_dns_zone_name = element(split("/", var.existing_private_dns_zone_id), length(split("/", var.existing_private_dns_zone_id)) - 1)
  private_dns_name               = local.existing_private_ds_zone ? local.existing_private_dns_zone_name : azurerm_private_dns_zone.dns[0].name
  private_dns_id                 = local.existing_private_ds_zone ? var.existing_private_dns_zone_id : azurerm_private_dns_zone.dns[0].id
  vnet_id = join("/", slice(split("/", var.subnet_id), 0, 9))
}
```

### 3. Validaciones
Las validaciones de las variables en `variables.tf` aseguran que los valores cumplan con las expectativas antes de aplicarse. Esto incluye:

- Validación de formato mediante expresiones regulares (`regex`).
- Restricción de longitud para identificadores (`length`).
- Verificación de valores opcionales o predeterminados.

Por ejemplo, para `subnet_id`:
```hcl
validation {
  condition = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/[^/]+/", var.subnet_id))
  error_message = "The subnet_id must follow the Azure format: /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/{resourceProviderNamespace}/{resourceType}/{resourceName}"
}
```

### 4. Reutilización de Recursos Existentes
Si se proporciona una zona DNS privada existente, el módulo reutiliza esta configuración en lugar de crear una nueva. Esto se gestiona con condicionales y variables locales.

---

## Flujo General

1. Se proporcionan los IDs de la subred, el recurso objetivo y otras configuraciones opcionales.
2. El módulo verifica las entradas y extrae información relevante sobre los recursos existentes.
3. Se crean o reutilizan recursos de DNS y endpoints según la configuración.
4. Los recursos se vinculan entre sí para habilitar el acceso privado y la resolución de DNS.

---

## Uso Previsto

Este módulo está diseñado para integrarse en entornos donde se requiere acceso privado a recursos en Azure, como bases de datos, almacenamiento, o servicios de análisis, garantizando seguridad y facilidad de configuración.

