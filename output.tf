# Number of Instance
output "num_instances" {
  value = "${var.num_instances}"
}

# Cluster Name
output "name_prefix" {
  value = "${var.name_prefix}"
}

# Instance Type
output "instance_type" {
  value = "${var.instance_type}"
}

# DCOS Version for prereq install
output "dcos_version" {
  value = "${var.dcos_version}"
}

# Tested OSes to install with prereq
output "dcos_instance_os" {
  value = "${var.dcos_instance_os}"
}

# Source image to boot from
output "image" {
  value = "${var.image}"
}

# Disk Type to Leverage
output "disk_type" {
  value = "${var.disk_type}"
}

# Disk Size in GB
output "disk_size" {
  value = "${var.disk_size}"
}

# Resource Group Name
output "resource_group_name" {
  value = "${var.resource_group_name}"
}

# Customer Provided Userdata
output "user_data" {
  value = "${var.user_data}"
}

# Network Security Group ID
output "network_security_group_id" {
  value = "${var.network_security_group_id}"
}

# SSH User
output "admin_username" {
  value = "${coalesce(var.admin_username, module.dcos-tested-oses.user)}"
}

# SSH Public Key
output "public_ssh_key" {
  value = "${var.public_ssh_key}"
}

# Public backend address pool 
output "public_backend_address_pool" {
  value = "${var.public_backend_address_pool}"
}

# Private backend address pool 
output "private_backend_address_pool" {
  value = "${var.private_backend_address_pool}"
}

# Subnet ID
output "subnet_id" {
  value = "${var.subnet_id}"
}

# Private IP Addresses
output "private_ips" {
  value = ["${azurerm_network_interface.instance_nic.*.private_ip_address}"]
}

# Public IP Addresses
output "public_ips" {
  value = ["${azurerm_public_ip.instance_public_ip.*.fqdn}"]
}
