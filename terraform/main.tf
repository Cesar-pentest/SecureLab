terraform {
  required_version = ">= 1.16.0"
}

resource "azurerm_resource_group" "securelab" {
  name     = "rg-securelab"
  location = "spaincentral"
}

resource "azurerm_container_registry" "securelab" {
  name                = "securelabacr"
  resource_group_name = "rg-securelab"
  location            = "spaincentral"
  sku                 = "Standard"
}

resource "azurerm_container_app_environment" "securelab" {
  name                       = "securelab-env"
  resource_group_name        = "rg-securelab"
  location                   = "spaincentral"
  log_analytics_workspace_id = "/subscriptions/31b7b62d-a7dc-4303-a873-08dc950dc94f/resourceGroups/rg-securelab/providers/Microsoft.OperationalInsights/workspaces/workspace-rgsecurelabg2H0"

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }
}

resource "azurerm_user_assigned_identity" "securelab" {
  name                = "securelab-identity"
  resource_group_name = "rg-securelab"
  location            = "spaincentral"
}

resource "azurerm_container_app" "securelab" {
  name                         = "securelab"
  resource_group_name          = "rg-securelab"
  container_app_environment_id = azurerm_container_app_environment.securelab.id
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"
  max_inactive_revisions       = 100

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.securelab.id]
  }

  registry {
    server   = azurerm_container_registry.securelab.login_server
    identity = azurerm_user_assigned_identity.securelab.id
  }

  ingress {
    external_enabled           = true
    allow_insecure_connections = false
    target_port                = 8080
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

 template {
    min_replicas = 0
    max_replicas = 1

    container {
      name   = "securelab"
      image  = "securelabacr.azurecr.io/securelab:build-42"
      cpu    = 0.5
      memory = "1Gi"
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].container[0].image
    ]
  }
}
  
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.securelab.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.securelab.principal_id
}
