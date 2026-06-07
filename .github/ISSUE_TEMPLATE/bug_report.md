---
name: Reporte de Error (Bug)
about: Crea un reporte para ayudarnos a mejorar los módulos
title: '[BUG] '
labels: bug
assignees: ''

---

**Descripción del Error**
Una descripción clara y concisa de lo que está fallando.

**Para Reproducir**
Pasos para reproducir el comportamiento:
1. Módulo utilizado: [e.g. module-storage-infrastructure]
2. Código de configuración de Terraform (oculta información sensible):
```hcl
module "storage" {
  ...
}
```
3. Comando ejecutado: `terraform apply`
4. Error obtenido:
```text
(Pegar el error aquí)
```

**Comportamiento Esperado**
Una descripción clara y concisa de lo que esperabas que sucediera.

**Entorno:**
 - Versión de Terraform: [e.g. 1.0.0]
 - Versión del Provider AzureRM: [e.g. 4.16]
 - OS: [e.g. iOS]

**Contexto Adicional**
Añade cualquier otro contexto sobre el problema aquí.
