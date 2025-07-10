terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.35.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "10ce0944-5960-42ed-8657-1a8177030014"
}

data "azurerm_container_registry" "main" {
  name = "ci-asr243-student1"
  resource_group_name = "rg-asr243-student1"
}

data "azurerm_resource_group" "main" {
  name     = "rg-asr243-student1"
}

resource "azurerm_user_assigned_identity" "acrpull" {
  location            = data.azurerm_resource_group.main.location
  name                = "uid-acrpull"
  resource_group_name = data.azurerm_resource_group.main.name
}

resource "azurerm_role_assignment" "ci_acrpull" {
  scope                = data.azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.acrpull.principal_id
}

resource "azurerm_container_group" "nginx" {
  name                = "ci-asr243-mfo"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  ip_address_type     = "Public"
  dns_name_label      = "ci-asr243-mfo"
  os_type             = "Linux"
  
  image_registry_credential {
    user_assigned_identity_id = azurerm_user_assigned_identity.acrpull.id
    server                    = data.azurerm_container_registry.main.login_server
  }

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.acrpull.id]
  }

  container {
    name   = "nginx"
    image  = "acrasr243mfo.azurecr.io/nginx:latest"
    cpu    = "1"
    memory = "1.5"

    ports {
      port     = 80
      protocol = "TCP"
    }
  }

  depends_on = [ azurerm_role_assignment.ci_acrpull ]
}
