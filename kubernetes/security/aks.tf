# Configure Azure Provider
provider "azurerm" {
  version = "=1.20"
}

resource "azurerm_resource_group" "rg" {
  name     = "<resource-group-name>"
  location = "westeurope"
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "<cluster-name>"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  dns_prefix          = "<prefix>"
  kubernetes_version  = "1.11.5"

  agent_pool_profile {
    name            = "default"
    count           = "1"
    vm_size         = "Standard_A1_v2"
    os_type         = "Linux"
    os_disk_size_gb = 30
  }

  service_principal {
    client_id     = "${var.client_id}"
    client_secret = "${var.client_secret}"
  }

  role_based_access_control {
    azure_active_directory {
      client_app_id     = "${var.ad_client_app_id}"
      server_app_id     = "${var.ad_server_app_id}"
      server_app_secret = "${var.ad_server_app_secret}"
      tenant_id         = "${var.ad_tenant_id}"
    }
    enabled = true
  }
}

output "kube_config" {
  value = "${azurerm_kubernetes_cluster.aks.kube_config_raw}"
}

output "host" {
  value = "${azurerm_kubernetes_cluster.aks.kube_config.0.host}"
}