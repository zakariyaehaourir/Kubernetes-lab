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