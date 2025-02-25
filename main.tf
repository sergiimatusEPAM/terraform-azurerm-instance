/**
 * [![Build Status](https://jenkins-terraform.mesosphere.com/service/dcos-terraform-jenkins/buildStatus/icon?job=dcos-terraform%2Fterraform-azurerm-instance%2Fsupport%252F0.2.x)](https://jenkins-terraform.mesosphere.com/service/dcos-terraform-jenkins/job/dcos-terraform/job/terraform-azurerm-instance/job/support%252F0.2.x/)
 *
 * Azure Instance
 * ============
 * The module creates AzureRM virtual machine instances
 *
 * EXAMPLE
 * -------
 *
 * ```hcl
 * module "dcos-master-instances" {
 *   source  = "dcos-terraform/instance/azurerm"
 *   version = "~> 0.2.0"
 *
 *   num                          = "${var.num}"
 *   location                     = "${var.location}"
 *   dcos_instance_os             = "${var.dcos_instance_os}"
 *   ssh_private_key_filename     = "${var.ssh_private_key_filename}"
 *   image                        = "${var.image}"
 *   resource_group_name          = "${var.resource_group_name}"
 *   ...
 * }
 * ```
 */

provider "azurerm" {}

locals {
  cluster_name = "${var.name_prefix != "" ? "${var.name_prefix}-${var.cluster_name}" : var.cluster_name}"
  private_key  = "${file(var.ssh_private_key_filename)}"
  agent        = "${var.ssh_private_key_filename == "/dev/null" ? true : false}"
}

module "dcos-tested-oses" {
  source  = "dcos-terraform/tested-oses/azurerm"
  version = "~> 0.2.0"

  providers = {
    azurerm = "azurerm"
  }

  os = "${var.dcos_instance_os}"
}

locals {
  image_publisher = "${length(var.image) > 0 ? lookup(var.image, "publisher", "") : module.dcos-tested-oses.azure_publisher }"
  image_sku       = "${length(var.image) > 0 ? lookup(var.image, "sku", "") : module.dcos-tested-oses.azure_sku }"
  image_version   = "${length(var.image) > 0 ? lookup(var.image, "version", "") : module.dcos-tested-oses.azure_version }"
  image_offer     = "${length(var.image) > 0 ? lookup(var.image, "offer", "") : module.dcos-tested-oses.azure_offer }"
}

# instance Node
resource "azurerm_managed_disk" "instance_managed_disk" {
  count                = "${var.num}"
  name                 = "${format(var.hostname_format, count.index + 1, local.cluster_name)}"
  location             = "${var.location}"
  resource_group_name  = "${var.resource_group_name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "${var.disk_size}"
}

# Public IP addresses for the Public Front End load Balancer
resource "azurerm_public_ip" "instance_public_ip" {
  count               = "${var.num}"
  name                = "${format(var.hostname_format, count.index + 1, local.cluster_name)}-pub-ip"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  allocation_method   = "Dynamic"
  domain_name_label   = "${format(var.hostname_format, count.index + 1, local.cluster_name)}"

  tags = "${merge(var.tags, map("Name", format(var.hostname_format, (count.index + 1), var.location, local.cluster_name),
                                "Cluster", local.cluster_name))}"
}

# Create an availability set
resource "azurerm_availability_set" "instance_av_set" {
  count                        = "${var.num == 0 ? 0 : 1}"
  name                         = "${format(var.hostname_format, count.index + 1, local.cluster_name)}-avset"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  platform_fault_domain_count  = "${var.avset_platform_fault_domain_count}"
  platform_update_domain_count = 1
  managed                      = true
}

# Instance NICs
resource "azurerm_network_interface" "instance_nic" {
  name                      = "${format(var.hostname_format, count.index + 1, local.cluster_name)}-nic"
  location                  = "${var.location}"
  resource_group_name       = "${var.resource_group_name}"
  network_security_group_id = "${var.network_security_group_id}"
  count                     = "${var.num}"

  ip_configuration {
    name                          = "${format(var.hostname_format, count.index + 1, local.cluster_name)}-ipConfig"
    subnet_id                     = "${var.subnet_id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${element(azurerm_public_ip.instance_public_ip.*.id, count.index)}"
  }

  tags = "${merge(var.tags, map("Name", format(var.hostname_format, (count.index + 1), var.location, local.cluster_name),
                                "Cluster", local.cluster_name))}"
}

resource "azurerm_virtual_machine" "instance" {
  name                             = "${format(var.hostname_format, count.index + 1, local.cluster_name)}"
  location                         = "${var.location}"
  resource_group_name              = "${var.resource_group_name}"
  network_interface_ids            = ["${element(azurerm_network_interface.instance_nic.*.id, count.index)}"]
  availability_set_id              = "${element(azurerm_availability_set.instance_av_set.*.id, 0)}"
  vm_size                          = "${var.vm_size}"
  count                            = "${var.num}"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "${contains(keys(var.image), "id") ? "" : module.dcos-tested-oses.azure_publisher}"
    offer     = "${contains(keys(var.image), "id") ? "" : module.dcos-tested-oses.azure_offer}"
    sku       = "${contains(keys(var.image), "id") ? "" : module.dcos-tested-oses.azure_sku}"
    version   = "${contains(keys(var.image), "id") ? "" : module.dcos-tested-oses.azure_version}"
    id        = "${lookup(var.image, "id", "")}"
  }

  storage_os_disk {
    name              = "os-disk-${format(var.hostname_format, count.index + 1, local.cluster_name)}"
    caching           = "ReadOnly"
    create_option     = "FromImage"
    managed_disk_type = "${var.disk_type}"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.instance_managed_disk.*.name[count.index]}"
    managed_disk_id = "${azurerm_managed_disk.instance_managed_disk.*.id[count.index]}"
    create_option   = "Attach"
    caching         = "None"
    lun             = 0
    disk_size_gb    = "${azurerm_managed_disk.instance_managed_disk.*.disk_size_gb[count.index]}"
  }

  os_profile {
    computer_name  = "${format(var.hostname_format, count.index + 1, local.cluster_name)}"
    admin_username = "${coalesce(var.admin_username, module.dcos-tested-oses.user)}"
    custom_data    = "${var.custom_data}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${coalesce(var.admin_username, module.dcos-tested-oses.user)}/.ssh/authorized_keys"
      key_data = "${file(var.public_ssh_key)}"
    }
  }

  os_profile_windows_config {
    provision_vm_agent = true
    enable_automatic_upgrades = false

    additional_unattend_config {
      component = "oobeSystem"
      content = "Microsoft-Windows-Shell-Sleep"
      pass = "AutoLogon"
      setting_name = "<AutoLogon><Password><Value>${var.admin_password}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>${var.admin_username}</Username></AutoLogon>"
    }
  }

  tags = "${merge(var.tags, map("Name", format(var.hostname_format, (count.index + 1), var.location, local.cluster_name),
                                "Cluster", local.cluster_name))}"
}
