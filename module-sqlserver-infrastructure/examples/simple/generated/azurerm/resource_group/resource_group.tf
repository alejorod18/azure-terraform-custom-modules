resource "azurerm_resource_group" "tfer--rg-biz-state-mach-tech-dev" {
  location = "westus"
  name     = "rg-biz-state-mach-tech-dev"

  tags = {
    application         = "cx-management"
    businessCriticality = "low"
    businessUnit        = "tech"
    costCenter          = "CeCoTech"
    createdBy           = "ovaloism"
    creationDate        = "2025-02-12T03:56:12Z"
    environment         = "dev"
    lastModifiedBy      = "ovaloism"
    managedBy           = "devops-team"
    scope               = "oboarding"
  }
}
