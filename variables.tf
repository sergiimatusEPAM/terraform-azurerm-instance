variable "num" {
  description = "How many instances should be created"
}

variable "location" {
  description = "Azure Region"
}

variable "cluster_name" {
  description = "Name of the DC/OS cluster"
}

variable "vm_size" {
  description = "Azure virtual machine size"
}

variable "dcos_instance_os" {
  description = "Operating system to use. Instead of using your own AMI you could use a provided OS."
}

variable "ssh_private_key_filename" {
  description = "Path to the SSH private key"

  # cannot leave this empty as the file() interpolation will fail later on for the private_key local variable
  # https://github.com/hashicorp/terraform/issues/15605
  default = "/dev/null"
}

variable "image" {
  description = "Source image to boot from"
  type        = "map"
  default     = {}
}

variable "disk_type" {
  description = "Disk Type to Leverage"
  default     = "Standard_LRS"
}

variable "disk_size" {
  description = "Disk Size in GB"
}

variable "resource_group_name" {
  description = "Name of the azure resource group"
}

variable "custom_data" {
  description = "User data to be used on these instances (cloud-init)"
  default     = ""
}

variable "admin_username" {
  description = "SSH User"
  default     = ""
}

variable "admin_password" {
  description = "Windows admin password"
  default = ""
}

variable "public_ssh_key" {
  description = "SSH Public Key"
  default     = ""
}

variable "tags" {
  description = "Add custom tags to all resources"
  type        = "map"
  default     = {}
}

variable "hostname_format" {
  description = "Format the hostname inputs are index+1, region, cluster_name"
  default     = "instance-%[1]d-%[2]s"
}

variable "public_backend_address_pool" {
  description = "Public backend address pool"
  type        = "list"
  default     = []
}

variable "private_backend_address_pool" {
  description = "Private backend address pool"
  type        = "list"
  default     = []
}

variable "network_security_group_id" {
  description = "Security Group Id"
  default     = ""
}

variable "subnet_id" {
  description = "Subnet ID"
}

variable "name_prefix" {
  description = "Name Prefix"
}

variable "avset_platform_fault_domain_count" {
  description = "Availability set platform fault domain count, differs from location to location"
  default     = 3
}

variable "is_windows" {
  description = "Flag to distinquish instance from Windows, by default Linux takes priority"
  default     = 0
}
