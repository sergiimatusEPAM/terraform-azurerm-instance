# SSH User
output "admin_username" {
  description = "admin username"
  value       = "${coalesce(var.admin_username, module.dcos-tested-oses.user)}"
}

# Private IP Addresses
output "private_ips" {
  description = "List of private ip addresses created by this module"
  value       = ["${azurerm_network_interface.instance_nic.*.private_ip_address}"]
}

# Public IP Addresses
output "public_ips" {
  description = "List of public ip addresses created by this module"
  value       = ["${azurerm_public_ip.instance_public_ip.*.fqdn}"]
}

# Returns the ID of the prereq script
output "prereq_id" {
  description = "prereq id"
  value       = "${join(",", flatten(list(null_resource.instance-prereq.*.id)))}"
}
