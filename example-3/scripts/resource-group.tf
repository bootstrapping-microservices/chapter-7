resource "azurerm_resource_group" "flixtube" {
  name     = var.resource_group_name
  location = var.location
}
