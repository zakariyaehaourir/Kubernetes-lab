output "vms_private_ips" {
  description = "Vms private IPs"
  value = {
    for role, instance in azurerm_linux_virtual_machine.virtual_linux_instances : role => instance.private_ip_address
  }
}

output "control_plan_public_ip" {
  description = "Pulbic Ip of the master node"
  value       = azurerm_linux_virtual_machine.virtual_linux_instances["control-plane"].public_ip_address
}

output "azure_ccm_identity_client_id" {
  description = "Client ID of Azure CCM managed identity"
  value       = azurerm_user_assigned_identity.azure_ccm.client_id
}

output "azure_ccm_identity_principal_id" {
  description = "Principal ID of Azure CCM managed identity"
  value       = azurerm_user_assigned_identity.azure_ccm.principal_id
}

output "azure_ccm_identity_resource_id" {
  description = "Resource ID of Azure CCM managed identity"
  value       = azurerm_user_assigned_identity.azure_ccm.id
}