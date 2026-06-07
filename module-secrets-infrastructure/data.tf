data "azurerm_client_config" "azure_provider_config" {}

data "github_actions_environment_secrets" "secrets" {
  count       = local.github_repository_name != "" ? 1 : 0
  name        = local.github_repository_name
  environment = data.azurerm_resource_group.rg.tags.environment
}

locals { secrets = local.github_repository_name != "" ? data.github_actions_environment_secrets.secrets[0].secrets : [] }

data "external" "get_secret" {
  for_each = toset([for s in local.secrets : s.name])
  program  = ["bash", "-c", "echo '{\"${each.value}\": \"'$(printenv ${each.value})'\"}'"]
}


data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "http" "my_public_ip" {
  url = "http://checkip.amazonaws.com"
}

data "external" "get_github_repository_name" {
  program = [
    "bash",
    "-c",
    "echo '{\"repository_name\": \"'$(echo $(printenv GITHUB_REPOSITORY) | awk -F'/' '{print $2}')'\"}'"
  ]
}

data "azurerm_client_config" "current" {}
