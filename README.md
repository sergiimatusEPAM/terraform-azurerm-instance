[![Build Status](https://jenkins-terraform.mesosphere.com/service/dcos-terraform-jenkins/job/dcos-terraform/job/terraform-azurerm-instance/job/master/badge/icon)](https://jenkins-terraform.mesosphere.com/service/dcos-terraform-jenkins/job/dcos-terraform/job/terraform-azurerm-instance/job/master/)
![HashiCorp's Terraform](https://cultivatedops-static.s3.amazonaws.com/thirdparty/terraform/logo-50.png)

This repository is a [Terraform](https://terraform.io/) Module for azurerm virtual machine instances

The module creates AzureRM virtual machine instances

# Usage

Add the module to your Terraform resources like so:

```
module "terraform-azurerm-instance" {
  source = "./terraform-module-terraform-azurerm-instance"
  arg1 = "foo"
}
```


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| admin_username | admin username | string | - | yes |
| dcos_instance_os | Operating system to use. Instead of using your own AMI you could use a provided OS. | string | - | yes |
| dcos_version | Specifies which DC/OS version instruction to use. Options: 1.9.0, 1.8.8, etc. See dcos_download_path or dcos_version tree for a full list. | string | - | yes |
| disk_size | disk size | string | - | yes |
| disk_type | Disk Type to Leverage. | string | `Standard_LRS` | no |
| hostname_format | Format the hostname inputs are index+1, region, cluster_name | string | `instance-%[1]d-%[2]s` | no |
| image | image | string | - | yes |
| instance_type | instance type | string | - | yes |
| location | location | string | - | yes |
| name_prefix | Cluster Name | string | - | yes |
| network_security_group_id | network security group id | string | `` | no |
| num_instances | num instances | string | - | yes |
| private_backend_address_pool | private backend address pool | list | `<list>` | no |
| public_backend_address_pool | public backend address pool | list | `<list>` | no |
| public_ssh_key | public ssh key | string | - | yes |
| resource_group_name | resource group name | string | - | yes |
| ssh_private_key_filename | Path to the SSH private key | string | `/dev/null` | no |
| subnet_id | Subnet ID | string | - | yes |
| tags | Add custom tags to all resources | map | `<map>` | no |
| user_data | User data to be used on these instances (cloud-init) | string | `` | no |

## Outputs

| Name | Description |
|------|-------------|
| admin_username | SSH User |
| dcos_instance_os | Tested OSes to install with prereq |
| dcos_version | DCOS Version for prereq install |
| disk_size | Disk Size in GB |
| disk_type | Disk Type to Leverage |
| image | Source image to boot from |
| instance_type | Instance Type |
| name_prefix | Cluster Name |
| network_security_group_id | Network Security Group ID |
| num_instances | Number of Instance |
| prereq_id | Returns the ID of the prereq script |
| private_backend_address_pool | Private backend address pool |
| private_ips | Private IP Addresses |
| public_backend_address_pool | Public backend address pool |
| public_ips | Public IP Addresses |
| public_ssh_key | SSH Public Key |
| resource_group_name | Resource Group Name |
| subnet_id | Subnet ID |
| user_data | Customer Provided Userdata |

