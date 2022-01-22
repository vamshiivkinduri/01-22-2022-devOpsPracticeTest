terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=2.82.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "StorageAccount"
    storage_account_name = "devtfivk"
    container_name       = "tf-dev"
    key                  = "resource/appservice"
    subscription_id      = "***************"
    }

}

provider "azurerm" {
  features {}
  subscription_id = "***************"
}
resource "azurerm_resource_group" "resource" {
  name     = var.resource_group_name
  location = "eastus2"
  tags = var.tags 
}

resource "azurerm_app_service_plan" "app-plan" {
  name                = var.app_service_plan_name
  location            = azurerm_resource_group.resource.location
  resource_group_name = azurerm_resource_group.resource.name
  kind = "App"
#  is_xenon = "false"
#  reserved = true
  sku {
    tier = "Standard"
    size = "S1"
  }
}
resource "azurerm_log_analytics_workspace" "log-analytics-work-space" {
  name                = "log-terraform-poc-devops-eastus2"
  location            = azurerm_resource_group.resource.location
  resource_group_name = azurerm_resource_group.resource.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}
resource "azurerm_application_insights" "appinsights" {
  name                = "appi-terraform-poc-devops-eastus2"
  location            = azurerm_resource_group.resource.location
  resource_group_name = azurerm_resource_group.resource.name
  workspace_id        = azurerm_log_analytics_workspace.log-analytics-work-space.id
  application_type    = "web"
}

output "instrumentation_key" {
  value = azurerm_application_insights.appinsights.instrumentation_key
}

output "app_id" {
  value = azurerm_application_insights.appinsights.app_id
}
# resource "azurerm_template_deployment" "main" {
#       name                = "MyApp-ARM"
#       resource_group_name = "${azurerm_resource_group.main.name}"
      
#       template_body = "${file("arm/appinsights.json")}"
      
#       parameters {
#         "myList" = "${join(",", var.myList)}"
#       }
      
#       deployment_mode = "Incremental"
# }

resource "azurerm_app_service" "myapp" {
  name                = var.app_service_name
  location            = azurerm_resource_group.resource.location
  resource_group_name = azurerm_resource_group.resource.name
  app_service_plan_id = azurerm_app_service_plan.app-plan.id
  
  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY"      = azurerm_application_insights.appinsights.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.appinsights.connection_string
  }  

  site_config {
     dotnet_framework_version = "v5.0"
     always_on = true

  }

  }
    
    


output "id" {
  value = azurerm_app_service_plan.app-plan.id
}