terraform {
    required_version = " >= 0.13 "
    
    required_providers {
            azurerm = {
                source = "hashicorp/azurerm"
                version = " >= 2.26"
            }
    }
}

provider "azurerm" {
    features{

    }
}

resource "azurerm_resource_group" "rg-aulainfra-tgocs"{
    name = "aulainfracloudterratgocs"
    location = "East US"
}