###########################################################
# 
# Author: Lucas Immanuel Nickel, Sebastian Rieger
# Date: May 23, 2024
# Remark: This code is not production ready as it disables certificate checks by default
# and sets kubeconfig file access to 644 instead of default 600
#
###########################################################

locals {
    ###########################################################
    #
    # Config parameters
    #
    # also add terraform.tfvars, see README at:
    #
    # https://github.com/srieger1/terraform-openstack-rke2/tree/hsfulda-example-2023-10/examples/hs-fulda
    #
    ###########################################################

    insecure         = true
    auth_url         = "https://10.32.4.182:5000/v3"
    object_store_url = "private-cloud2.informatik.hs-fulda.de:6780"
    region           = "RegionOne"

    cluster_name     = "${var.project}-k8s"
    image_name       = "ubuntu-22.04-jammy-x86_64"
    flavor_name      = "m1.medium"
    system_user      = "ubuntu"
    floating_ip_pool = "ext_net"
    ssh_pubkey_file  = "~/.ssh/id_rsa.pub"
    #ssh_pubkey_file  = "~/.ssh/id_ed25519.pub"
    dns_server       = "10.33.16.100"
    manifests_folder = "./hsfd-manifests"
    rke2_version     = "v1.28.4+rke2r1"

    ###########################################################
}

module "rke2" {
  source = "./../.."
  insecure            = local.insecure
  bootstrap           = true
  name                = local.cluster_name
  ssh_authorized_keys = [local.ssh_pubkey_file]
  floating_pool       = local.floating_ip_pool
  rules_ssh_cidr      = "0.0.0.0/0"
  rules_k8s_cidr      = "0.0.0.0/0"
  manifests_folder    = local.manifests_folder

  servers = [{
    name = "server"
    flavor_name = local.flavor_name
    image_name  = local.image_name
    system_user = local.system_user
    boot_volume_size = 8
    rke2_version     = local.rke2_version
    rke2_volume_size = 8
    rke2_volume_device = "/dev/vdb"
    rke2_config = <<EOF
# https://docs.rke2.io/install/install_options/server_config/
write-kubeconfig-mode: "0644"
EOF
  }]

  agents = [
    {
      name        = "pool"
      #nodes_count = 1
      nodes_count = 3
      flavor_name = local.flavor_name
      image_name  = local.image_name
      system_user = local.system_user
      boot_volume_size = 8
      rke2_version     = local.rke2_version
      rke2_volume_size = 8
      rke2_volume_device = "/dev/vdb"
    }
  ]

  dns_nameservers4      = [local.dns_server]
  ff_autoremove_agent   = "30s"
  ff_write_kubeconfig   = true
  ff_native_backup      = true
  ff_wait_ready         = true

  identity_endpoint     = local.auth_url
  object_store_endpoint = local.object_store_url

  kube_apiserver_resources = {
    requests = {
      cpu    = "75m"
      memory = "128M"
    }
  }

  kube_scheduler_resources = {
    requests = {
      cpu    = "75m"
      memory = "128M"
    }
  }

  kube_controller_manager_resources = {
    requests = {
      cpu    = "75m"
      memory = "128M"
    }
  }

  etcd_resources = {
    requests = {
      cpu    = "75m"
      memory = "128M"
    }
  }

  backup_schedule = "0 6 1 * *"
  backup_retention = 20
}

variable "project" {
  type = string
}

variable "username" {
  type = string
}

variable "password" {
  type = string
}

output "floating_ip" {
  value = module.rke2.external_ip
}

provider "openstack" {
  insecure    = local.insecure
  tenant_name = var.project
  user_name   = var.username
  password    = var.password
  auth_url    = local.auth_url
  region      = local.region
}

terraform {
  required_version = ">= 0.14.0"

  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = ">= 2.0.0"
    }
  }
}
