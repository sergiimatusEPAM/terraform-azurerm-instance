[![Build Status](https://jenkins-terraform.mesosphere.com/service/dcos-terraform-jenkins/job/dcos-terraform/job/terraform-azurerm-instance/job/master/badge/icon)](https://jenkins-terraform.mesosphere.com/service/dcos-terraform-jenkins/job/dcos-terraform/job/terraform-azurerm-instance/job/master/)

The module creates AzureRM virtual machine instances

## EXAMPLE

```hcl
module "dcos-master-instances" {
  source  = "dcos-terraform/instance/azurerm"
  version = "~> 0.1.0"

  num_instances                = "${var.num_masters}"
  location                     = "${var.location}"
  dcos_version                 = "${var.dcos_version}"
  dcos_instance_os             = "${var.dcos_instance_os}"
  ssh_private_key_filename     = "${var.ssh_private_key_filename}"
  image                        = "${var.image}"
  resource_group_name          = "${var.resource_group_name}"
  ...
}
```


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| admin_username | SSH User | string | - | yes |
| custom_data | User data to be used on these instances (cloud-init) | string | `` | no |
| dcos_instance_os | Operating system to use. Instead of using your own AMI you could use a provided OS. | string | - | yes |
| dcos_version | Specifies which DC/OS version instruction to use. Options: 1.9.0, 1.8.8, etc. See dcos_download_path or dcos_version tree for a full list. | string | - | yes |
| disk_size | Disk Size in GB | string | - | yes |
| disk_type | Disk Type to Leverage | string | `Standard_LRS` | no |
| hostname_format | Format the hostname inputs are index+1, region, cluster_name | string | `instance-%[1]d-%[2]s` | no |
| image | Source image to boot from | map | `<map>` | no |
| location | Azure Region | string | - | yes |
| name_prefix | Cluster Name | string | - | yes |
| network_security_group_id | Security Group Id | string | `` | no |
| num | How many instances should be created | string | - | yes |
| private_backend_address_pool | Private backend address pool | list | `<list>` | no |
| public_backend_address_pool | Public backend address pool | list | `<list>` | no |
| resource_group_name | Name of the azure resource group | string | - | yes |
| ssh_private_key_filename | Path to the SSH private key | string | `/dev/null` | no |
| ssh_public_key | SSH public key in authorized keys format (e.g. 'ssh-rsa ..') to be used with the instances. Make sure you added this key to your ssh-agent. | string | `` | no |
| subnet_id | Subnet ID | string | - | yes |
| tags | Add custom tags to all resources | map | `<map>` | no |
| vm_size | Azure virtual machine size | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| admin_username | SSH User |
| prereq_id | Returns the ID of the prereq script |
| private_ips | Private IP Addresses |
| public_ips | Public IP Addresses |

