provider "azurerm" {}

locals {
  private_key = "${file(var.ssh_private_key_filename)}"
  agent       = "${var.ssh_private_key_filename == "/dev/null" ? true : false}"
}

module "dcos-tested-oses" {
  source  = "dcos-terraform/azurerm-tested-oses/template"
  version = "~> 0.0"

  providers = {
    google = "azurerm"
  }

  os           = "${var.dcos_instance_os}"
  region       = "${var.location}"
  dcos_version = "${var.dcos_version}"
}

# instance Node
resource "azurerm_managed_disk" "instance_managed_disk" {
  count                = "${var.num_instances}"
  name                 = "${format(var.hostname_format, count.index + 1, var.name_prefix)}-instance-${count.index + 1}"
  location             = "${var.location}"
  resource_group_name  = "${var.resource_group_name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "${var.disk_size}"
}

# Public IP addresses for the Public Front End load Balancer
resource "azurerm_public_ip" "instance_public_ip" {
  count                        = "${var.num_instances}"
  name                         = "${format(var.hostname_format, count.index + 1, var.name_prefix)}-instance-pub-ip-${count.index + 1}"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  public_ip_address_allocation = "dynamic"
  domain_name_label            = "${format(var.hostname_format, count.index + 1, var.name_prefix)}-instance-${count.index + 1}"

  tags = "${merge(var.tags, map("Name", format(var.hostname_format, (count.index + 1), var.location, var.name_prefix),
                                "Cluster", var.name_prefix))}"
}

# Create an availability set
resource "azurerm_availability_set" "instance_av_set" {
  name                         = "${format(var.hostname_format, count.index + 1, var.name_prefix)}-instance-avset"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  platform_fault_domain_count  = 3
  platform_update_domain_count = 1
  managed                      = true
}

# Retrieve the network interface objects to consume metedata information about them
data "azurerm_network_interface" "instance" {
  count                 = "${length(var.network_instance_id)}"
  network_interface_ids = ["${element(var.network_instance_id, count.index)}"]
  resource_group_name   = "${var.resource_group_name}"
}

# Instance NICs
resource "azurerm_network_interface" "instance_nic" {
  name                      = "${format(var.hostname_format, count.index + 1, var.name_prefix)}-nic"
  location                  = "${var.location}"
  resource_group_name       = "${var.resource_group_name}"
  network_security_group_id = "${var.network_security_group_id}"
  count                     = "${var.num_instances}"

  ip_configuration {
    name                                    = "${format(var.hostname_format, count.index + 1, var.name_prefix)}-ipConfig"
    subnet_id                               = "${var.subnet_id}"
    private_ip_address_allocation           = "dynamic"
    public_ip_address_id                    = "${element(azurerm_public_ip.instance_public_ip.*.id, count.index)}"
    load_balancer_backend_address_pools_ids = ["${var.public_backend_address_pool}", "${var.private_backend_address_pool}"]
  }

  tags = "${merge(var.tags, map("Name", format(var.hostname_format, (count.index + 1), var.location, var.name_prefix),
                                "Cluster", var.name_prefix))}"
}

# Master VM Coniguration
resource "azurerm_virtual_machine" "instance" {
  name                             = "${format(var.hostname_format, count.index + 1, var.name_prefix)}-instance-${count.index + 1}"
  location                         = "${var.location}"
  resource_group_name              = "${var.resource_group_name}"
  network_interface_ids            = ["${element(azurerm_network_interface.instance_nic.*.id, count.index)}"]
  availability_set_id              = "${azurerm_availability_set.instance_av_set.id}"
  vm_size                          = "${var.instance_type}"
  count                            = "${var.num_instances}"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "${module.dcos-tested-oses.azure_publisher}"
    offer     = "${module.dcos-tested-oses.azure_offer}"
    sku       = "${module.dcos-tested-oses.azure_sku}"
    version   = "${module.dcos-tested-oses.azure_version}"
  }

  storage_os_disk {
    name              = "os-disk-instance-${count.index + 1}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "${var.disk_type}"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.instance_managed_disk.*.name[count.index]}"
    managed_disk_id = "${azurerm_managed_disk.instance_managed_disk.*.id[count.index]}"
    create_option   = "Attach"
    lun             = 0
    disk_size_gb    = "${azurerm_managed_disk.instance_managed_disk.*.disk_size_gb[count.index]}"
  }

  os_profile {
    computer_name  = "instance-${count.index + 1}"
    admin_username = "${coalesce(var.admin_username, module.dcos-tested-oses.user)}"
    custom_data    = "${var.user_data}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${coalesce(var.admin_username, module.dcos-tested-oses.user)}/.ssh/authorized_keys"
      key_data = "${var.public_ssh_key}"
    }
  }

  # OS init script
  provisioner "file" {
    content     = "${module.dcos-tested-oses.os-setup}"
    destination = "/tmp/os-setup.sh"

    connection {
      type        = "ssh"
      user        = "${coalesce(var.admin_username, module.dcos-tested-oses.user)}"
      host        = "${element(azurerm_public_ip.instance_public_ip.*.fqdn, count.index)}"
      private_key = "${local.private_key}"
      agent       = "${local.agent}"
    }
  }

  # We run a remote provisioner on the instance after creating it.
  # In this case, we just install nginx and start it. By default,
  # this should be on port 80
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/os-setup.sh",
      "sudo bash /tmp/os-setup.sh",
    ]

    connection {
      type        = "ssh"
      user        = "${coalesce(var.admin_username, module.dcos-tested-oses.user)}"
      host        = "${element(azurerm_public_ip.instance_public_ip.*.fqdn, count.index)}"
      private_key = "${local.private_key}"
      agent       = "${local.agent}"
    }
  }

  tags = "${merge(var.tags, map("Name", format(var.hostname_format, (count.index + 1), var.location, var.name_prefix),
                                "Cluster", var.name_prefix))}"
}
