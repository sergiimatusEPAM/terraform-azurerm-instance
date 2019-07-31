output "admin_username" {
  description = "SSH User"
  value       = "${coalesce(var.admin_username, module.dcos-tested-oses.user)}"
}

output "admin_password" {
  description = "Windows admin password"
  value       = "${var.admin_password}"
}

output "instance_nic_ids" {
  description = "List of instance nic ids created by this module"
  value       = ["${azurerm_network_interface.instance_nic.*.id}"]
}

output "private_ips" {
  description = "List of private ip addresses created by this module"
  value       = ["${azurerm_network_interface.instance_nic.*.private_ip_address}"]
}

output "public_ips" {
  description = "List of public ip addresses created by this module"
  value       = ["${azurerm_public_ip.instance_public_ip.*.fqdn}"]
}
