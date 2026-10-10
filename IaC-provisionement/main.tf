resource "azurerm_resource_group" "global" {
  name     = "rg-k8s-lab"
  location = var.location
}