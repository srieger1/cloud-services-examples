###########################################################
#
# Author: Lucas Immanuel Nickel, Sebastian Rieger, Yannis Liebermann
# Date: 12/2025
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
    auth_url         = "https://private-cloud.informatik.hs-fulda.de:5000"
    object_store_url = "https://10.32.4.32:443"
    region           = "RegionOne"
    cacert_file      = "./os-trusted-cas"

    cluster_name     = lower("${var.project}-k8s")
    image_name       = "ubuntu-22.04-jammy-server-cloud-image-amd64"
    flavor_name      = "m1.medium"
    system_user      = "ubuntu"
    floating_ip_pool = "ext_net"
    ssh_pubkey_file  = "~/.ssh/id_rsa.pub"
    #ssh_pubkey_file  = "~/.ssh/id_ed25519.pub"
    dns_server       = "10.33.16.100"
    rke2_version     = "v1.30.3+rke2r1"

    ###########################################################
}

module "rke2" {
  # source = "zifeo/rke2/openstack"
  # version = ""
  source = "git::https://github.com/srieger1/terraform-openstack-rke2.git?ref=hsfulda-example"

  insecure            = local.insecure
  #cacert_file          = base64encode(file(local.cacert_file))

  # must be true for single server cluster or
  # only on the first run for high-availability cluster
  bootstrap           = true
  name                = local.cluster_name
  ssh_authorized_keys = [local.ssh_pubkey_file]
  floating_pool       = local.floating_ip_pool
  # should be restricted to secure bastion
  rules_ssh_cidr      = [ "0.0.0.0/0" ]
  rules_k8s_cidr      = [ "0.0.0.0/0" ]
  # auto load manifest form a folder (https://docs.rke2.io/advanced#auto-deploying-manifests)
  manifests_folder = "./manifests"

  servers = [{
    name = "controller"
    flavor_name = local.flavor_name
    image_name  = local.image_name
    system_user = local.system_user
    boot_volume_size = 6
    rke2_version     = local.rke2_version
    rke2_volume_size = 8
    rke2_volume_device = "/dev/vdb"
    # https://docs.rke2.io/install/install_options/server_config/
    rke2_config = <<EOF
# https://docs.rke2.io/install/install_options/server_config/
write-kubeconfig-mode: "0644"
EOF
  }]

  agents = [
    {
      name        = "worker"
      nodes_count = 1
      #nodes_count = 3
      flavor_name = local.flavor_name
      image_name  = local.image_name
      # if you want a fixed version
      # image_uuid = "..."
      system_user = local.system_user
      boot_volume_size = 6
      rke2_version     = local.rke2_version
      #rke2_volume_size = 8
      rke2_volume_size = 20
      rke2_volume_device = "/dev/vdb"
    }
  ]

  backup_schedule  = "0 6 1 * *" # once a month
  backup_retention = 20

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
  #vip_interface       = "ens2"
  dns_nameservers4    = [local.dns_server]
  # enable automatically agent removal of the cluster (wait max for 30s)
  ff_autoremove_agent = "30s"
  # rewrite kubeconfig
  ff_write_kubeconfig = true
  # deploy etcd backup
  ff_native_backup    = true
  # wait for the cluster to be ready when deploying
  ff_wait_ready       = true

  identity_endpoint     = local.auth_url
  object_store_endpoint = local.object_store_url

  registries = {
    mirrors = {
      "*": {
        endpoint = [
          "https://harbor.cs.hs-fulda.de"
        ]
      }
    }
  }
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
  # change to ca_path
  insecure    = local.insecure
  tenant_name = var.project
  user_name   = var.username
  # checkov:skip=CKV_OPENSTACK_1
  password    = var.password
  auth_url    = local.auth_url
  region      = local.region
  cacert_file = local.cacert_file
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
