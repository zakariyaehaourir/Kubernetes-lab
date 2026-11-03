resource "azurerm_user_assigned_identity" "azure_ccm" {
  name                = "cloud-manager-assiged-identity"
  location            = var.location
  resource_group_name = azurerm_resource_group.global.name

  tags = {
    Environment = var.env
    Project     = var.project
  }
}

resource "azurerm_role_definition" "azure_ccm" {
  name  = "ccm-permisions"
  scope = azurerm_resource_group.global.id

  permissions {
    actions = [
      "Microsoft.Network/loadBalancers/read",
      "Microsoft.Network/loadBalancers/write",
      "Microsoft.Network/loadBalancers/delete",

      "Microsoft.Network/publicIPAddresses/read",
      "Microsoft.Network/publicIPAddresses/write",
      "Microsoft.Network/publicIPAddresses/delete",

      "Microsoft.Network/networkInterfaces/read",
      "Microsoft.Network/networkInterfaces/write",

      "Microsoft.Network/virtualNetworks/read",
      "Microsoft.Network/virtualNetworks/subnets/read",

      "Microsoft.Network/virtualNetworks/subnets/join/action", #atache LoadBalancer to subnet

      "Microsoft.Compute/virtualMachines/read",
    ]
    not_actions      = []
    data_actions     = []
    not_data_actions = []
  }

  assignable_scopes = [
    azurerm_resource_group.global.id
  ]


}

resource "azurerm_role_assignment" "azure_ccm" {
  description        = "Attach Cloud controll manager role definition to ccm identity"
  scope              = azurerm_resource_group.global.id
  role_definition_id = azurerm_role_definition.azure_ccm.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.azure_ccm.principal_id
}