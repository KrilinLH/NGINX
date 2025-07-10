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
}

data "azurerm_client_config" "main" {
}

data "azurerm_container_registry" "main" {
  name                = "ci-asr243-student1"
  resource_group_name = "rg-asr243-student1"
}

resource "azurerm_resource_group" "main" {
  name     = "rg-asr243-student1"
}

resource "azurerm_container_group" "nginx" {
  name                = "example-continst"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  ip_address_type     = "Public"
  dns_name_label      = "ci-asr243-student1_2"
  os_type             = "Linux"

  container {
    name   = "NGINX"
    image  = "acrasr243mfo.azurecr.io/nginx:latest"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 80
      protocol = "TCP"
    }
  }
}

identity {
type = "SystemAssigned"
}

resource "azurerm_role_assignment" "ci_acrpull" {
  scope                = data.azurerm_container_registry.main.id
  role_definition_name = "Reader"
  principal_id         = azurerm_container_group.nginx.identity[0].principal_id
}
