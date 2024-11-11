# Define IntServ group number
# TODO: change to use OS env vars etc.
variable "group_number" {
  type = string
  default = "20"
}

## OpenStack credentials can be used in a more secure way by using
## cloud.yaml from https://private-cloud.informatik.hs-fulda.de/project/api_access/clouds.yaml/

# Define OpenStack credentials, project config etc.
locals {
  auth_url          = "https://private-cloud.informatik.hs-fulda.de:5000/v3"
  user_name         = "IntServ${var.group_number}"
  user_password     = "<password of your group here, private-cloud is only reachable via vpn>"
  tenant_name       = "IntServ${var.group_number}"
  #network_name     = "IntServ${var.group_number}-net"
  router_name       = "IntServ${var.group_number}-router"
  image_name        = "Ubuntu 20.04 - Focal Fossa - 64-bit - Cloud Based Image"
  flavor_name       = "m1.medium"
  region_name       = "RegionOne"
  rke_flavor_name   = "m1.medium"
  availability_zone = "nova"
  domain_name       = "Default"
# possibly set floating_ip_pool = "" to avoid assigning floating ips to
# every created node and use only load balancer as frontend, however needed
# for node port forwarding etc. using kube proxy
  floating_ip_pool  = "public1"
  ssh_user          = "ubuntu"
}

# Define OpenStack provider
terraform {
required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = ">= 1.46.0"
    }
    rancher2 = {
      source = "rancher/rancher2"
      version = ">= 1.22.2"
    }
  }
}

# Configure the OpenStack Provider
provider "openstack" {
  user_name   = local.user_name
  tenant_name = local.tenant_name
  password    = local.user_password
  auth_url    = local.auth_url
  region      = local.region_name
  use_octavia = true
}



###########################################################################
#
# create keypair
#
###########################################################################

# import keypair, if public_key is not specified, create new keypair to use
resource "openstack_compute_keypair_v2" "terraform-rancher-keypair" {
  name       = "my-terraform-rancher-pubkey"
  # public_key = file("~/.ssh/id_ed25519.pub")
}



###########################################################################
#
# create security group
#
###########################################################################

resource "openstack_networking_secgroup_v2" "terraform-rancher-secgroup" {
  name        = "my-terraform-rancher-secgroup"
  description = "for terraform rancher instances"
}

# TODO: possibly cleanup unnecessary ports?

resource "openstack_networking_secgroup_rule_v2" "terraform-secgroup-rule-ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  #remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.terraform-rancher-secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "terraform-secgroup-rule-http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  #remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.terraform-rancher-secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "terraform-secgroup-rule-https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  #remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.terraform-rancher-secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "terraform-secgroup-rule-2376" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 2376
  port_range_max    = 2376
  #remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.terraform-rancher-secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "terraform-secgroup-rule-2379" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 2379
  port_range_max    = 2379
  #remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.terraform-rancher-secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "terraform-secgroup-rule-2380" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 2380
  port_range_max    = 2380
  #remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.terraform-rancher-secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "terraform-secgroup-rule-6443" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  #remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.terraform-rancher-secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "terraform-secgroup-rule-9099" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 9099
  port_range_max    = 9099
  #remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.terraform-rancher-secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "terraform-secgroup-rule-10250" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10250
  port_range_max    = 10250
  #remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.terraform-rancher-secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "terraform-secgroup-rule-10254" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10254
  port_range_max    = 10254
  #remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.terraform-rancher-secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "terraform-secgroup-rule-8472" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 8472
  port_range_max    = 8472
  #remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.terraform-rancher-secgroup.id
}



###########################################################################
#
# create network
#
###########################################################################

resource "openstack_networking_network_v2" "terraform-rancher-network-1" {
  name           = "my-terraform-rancher-network-1"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "terraform-rancher-subnet-1" {
  name            = "my-terraform-rancher-subnet-1"
  network_id      = openstack_networking_network_v2.terraform-rancher-network-1.id
  cidr            = "192.168.254.0/24"
  dns_nameservers = [ "192.168.76.253" ]
  ip_version      = 4
}

data "openstack_networking_router_v2" "router-1" {
  name = local.router_name
}

resource "openstack_networking_router_interface_v2" "router_interface_1" {
  router_id = data.openstack_networking_router_v2.router-1.id
  subnet_id = openstack_networking_subnet_v2.terraform-rancher-subnet-1.id
}



###########################################################################
#
# create instances
#
###########################################################################

resource "openstack_compute_instance_v2" "terraform-rancher-instance-1" {
  name              = "my-terraform-rancher-instance-1"
  image_name        = local.image_name
  flavor_name       = local.flavor_name
  key_pair          = openstack_compute_keypair_v2.terraform-rancher-keypair.name
  security_groups   = [openstack_networking_secgroup_v2.terraform-rancher-secgroup.name]

  network {
    uuid = openstack_networking_network_v2.terraform-rancher-network-1.id
  }

  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get -y upgrade
    curl https://releases.rancher.com/install-docker/20.10.sh | sh
    sudo docker run --privileged -d --restart=unless-stopped -p 80:80 -p 443:443 --env CATTLE_BOOTSTRAP_PASSWORD=this-is-not-a-secure-bootstrap-pw rancher/rancher
    #sudo docker ps
    #sudo docker logs $(sudo docker ps | grep rancher | cut -d " " -f 1) 2>&1 | grep "Bootstrap Password:"
  EOF

  depends_on = [
    openstack_networking_subnet_v2.terraform-rancher-subnet-1
  ]
}



###########################################################################
#
# assign floating ip to rancher instance
#
###########################################################################
resource "openstack_networking_floatingip_v2" "fip_1" {
  pool    = "public1"
}

resource "openstack_compute_floatingip_associate_v2" "fip_1" {
  floating_ip = "${openstack_networking_floatingip_v2.fip_1.address}"
  instance_id = "${openstack_compute_instance_v2.terraform-rancher-instance-1.id}"
}



###########################################################################
#
# bootstrap rancher
#
# takes roughly ~8 minutes currently, hence the long timeout
# ~5 mins to install Ubuntu and installing updates
# ~3 mins to install docker and pull/start rancher container
#
###########################################################################

# Provider bootstrap config
provider "rancher2" {
  alias = "bootstrap"

  api_url   = "https://${openstack_networking_floatingip_v2.fip_1.address}"
  bootstrap = true
  insecure = true
  timeout = "900s"
}

# Create a new rancher2_bootstrap for Rancher v2.6.0 and above
resource "rancher2_bootstrap" "admin" {
  provider = rancher2.bootstrap
  initial_password = "this-is-not-a-secure-bootstrap-pw"
  password = "this-is-not-a-secure-admin-pw"
  telemetry = true
  token_update=true

  depends_on = [
    openstack_compute_floatingip_associate_v2.fip_1,
    openstack_compute_instance_v2.terraform-rancher-instance-1,
    openstack_networking_secgroup_rule_v2.terraform-secgroup-rule-ssh, 
    openstack_networking_secgroup_rule_v2.terraform-secgroup-rule-http, 
    openstack_networking_secgroup_rule_v2.terraform-secgroup-rule-https, 
    openstack_networking_secgroup_rule_v2.terraform-secgroup-rule-2376,
    openstack_networking_secgroup_rule_v2.terraform-secgroup-rule-2379,
    openstack_networking_secgroup_rule_v2.terraform-secgroup-rule-2380,
    openstack_networking_secgroup_rule_v2.terraform-secgroup-rule-6443,
    openstack_networking_secgroup_rule_v2.terraform-secgroup-rule-9099,
    openstack_networking_secgroup_rule_v2.terraform-secgroup-rule-10250,
    openstack_networking_secgroup_rule_v2.terraform-secgroup-rule-10254,
    openstack_networking_secgroup_rule_v2.terraform-secgroup-rule-8472,
    openstack_networking_router_interface_v2.router_interface_1
  ]
}

# Rancher2 administration provider
# provider chaining/using multiple providers should be avoided?
provider "rancher2" {
  alias = "admin"

  api_url  = "https://${openstack_networking_floatingip_v2.fip_1.address}"
  insecure = true
  # ca_certs  = data.kubernetes_secret.rancher_cert.data["ca.crt"]
  token_key = rancher2_bootstrap.admin.token
}

###########################################################################
#
# enable rancher node driver openstack
#
###########################################################################

#data "rancher2_node_driver" "OpenStack" {
#  provider = rancher2.admin
#  name = "openstack"
#}

# Create a new rancher2 Node Driver
# TODO: creates a new builtin driver, maybe better to change existing one
resource "rancher2_node_driver" "OpenStack" {
  provider = rancher2.admin
  name = "openstack"
  active = true
  builtin = true
  url = "local://"
  # external_id = data.rancher2_node_driver.OpenStack

  depends_on = [
    rancher2_bootstrap.admin
  ]
}



###########################################################################
#
# create rancher node template for hsfd openstack
#
###########################################################################

resource "rancher2_node_template" "hsfd-rancher-openstack" {
  provider = rancher2.admin
  name = "hsfd-rancher-openstack"
  driver_id = rancher2_node_driver.OpenStack.id
  openstack_config {
    auth_url = local.auth_url
    availability_zone = local.availability_zone
    region = local.region_name
    username = local.user_name
    # TODO: (Optional/Sensitive) OpenStack password. Mandatory on Rancher v2.0.x and v2.1.x. Use rancher2_cloud_credential from Rancher v2.2.x (string)
    password = local.user_password
    active_timeout = "200"
    domain_name = local.domain_name
    boot_from_volume = false
    flavor_name = local.rke_flavor_name
    # to prevent node from consuming a floating IP comment out the next line
    floating_ip_pool = local.floating_ip_pool
    image_name = local.image_name
    ip_version = "4"
    keypair_name = openstack_compute_keypair_v2.terraform-rancher-keypair.name
    net_id = openstack_networking_network_v2.terraform-rancher-network-1.id
    sec_groups = openstack_networking_secgroup_v2.terraform-rancher-secgroup.name
    ssh_user = local.ssh_user
    private_key_file = openstack_compute_keypair_v2.terraform-rancher-keypair.private_key
    tenant_name = local.tenant_name
  }
  # TODO: get latest recommended string possible?
  engine_install_url = "https://releases.rancher.com/install-docker/20.10.sh"

  depends_on = [
    rancher2_node_driver.OpenStack
  ]
}



###########################################################################
#
# create rke template for hsfd openstack
#
###########################################################################

data "openstack_identity_project_v3" "my-project" {
  name = local.tenant_name
}

data "openstack_networking_network_v2" "public1" {
  name = local.floating_ip_pool
}

# Create a new rancher2 Cluster Template
resource "rancher2_cluster_template" "hsfd-rke-openstack" {
  provider = rancher2.admin
  name = "hsfd-rke-openstack"
  template_revisions {
    name = "V1"
    cluster_config {
      rke_config {
        cloud_provider {
          name = "openstack"
          openstack_cloud_provider {
            block_storage {
              ignore_volume_az = true
              trust_device_path = false
              bs_version = "v3"
            }
            global {
              auth_url = local.auth_url
              domain_name = local.domain_name
              tenant_id = data.openstack_identity_project_v3.my-project.id
              username = local.user_name
              password = local.user_password
            }
            load_balancer {
              create_monitor = false
              floating_network_id = data.openstack_networking_network_v2.public1.id
              lb_version = "v2"
              manage_security_groups = true
              monitor_max_retries = 0
              subnet_id = openstack_networking_subnet_v2.terraform-rancher-subnet-1.id
              use_octavia = true
            }
            metadata {
              request_timeout = 0
            }
            route {
              router_id = data.openstack_networking_router_v2.router-1.id
            }
          }
        }
      }
    }
    default = true
  }
  description = "Terraform RKE template for HSFD OpenStack"

  depends_on = [
    rancher2_node_template.hsfd-rancher-openstack
  ]
}



###########################################################################
#
# wait for rancher host to be fully initialized, fixes cluster deployment
# hanging in:
#
# "Kubernetes version (spec.rancherKubernetesEngineConfig.
#  kubernetesVersion) is unset"
#
# that occurs in our recent rancher deployments since November 2022
#
# fix needs to be improved, e.g., by calling Rancher API to wait for k8s
# version to be available etc., though this should normaly be complete 
# after bootstrapping and was like that over that last years?
#
###########################################################################

resource "time_sleep" "wait_for_k8sversion" {
  create_duration = "30s"

  depends_on = [
    rancher2_cluster_template.hsfd-rke-openstack
  ]
}



###########################################################################
#
# create rke demo cluster
#
# takes about 8 mins to install with one (all-in-one) cluster node
#
###########################################################################

resource "rancher2_cluster" "hsfd-rke-demo" {
  provider = rancher2.admin
  name = "hsfd-rke-demo"
  cluster_template_id = rancher2_cluster_template.hsfd-rke-openstack.id
  cluster_template_revision_id = rancher2_cluster_template.hsfd-rke-openstack.template_revisions.0.id
  
# if instance is gone before deleting the cluster, we'll not be able to
# reach rke anymore
  depends_on = [
    time_sleep.wait_for_k8sversion,
    rancher2_cluster_template.hsfd-rke-openstack,
  ]
}

# Create a new rancher2 Node Pool
resource "rancher2_node_pool" "pool1" {
  provider = rancher2.admin
  cluster_id =  rancher2_cluster.hsfd-rke-demo.id
  name = "ctrl-etcd-work"
  hostname_prefix =  "ctrl-etcd-work"
  node_template_id = rancher2_node_template.hsfd-rancher-openstack.id
  quantity = 1
  control_plane = true
  etcd = true
  worker = true

  depends_on = [rancher2_cluster.hsfd-rke-demo]
}



output "finished" {
  value = <<FINISHED
  You can access rancher at https://${openstack_networking_floatingip_v2.fip_1.address}.
  You need a VPN connection if you want to access the node from external networks.

  You can login using user 'admin' and password 'this-is-not-a-secure-admin-pw'.
  Progress of the cluster deployment can be seen in 'Cluster Management'.

  The default 1-node cluster deployment should be ready in about 8 mins in our
  environment.

  The cluster deployment needs to be able to reserve a new floating IP, so be sure
  to have a floating IP avaiable. You can disable the assignment of a floating IP
  for each cluster node, as services will be accessible through a load balancer.
  However, then you cannot use kubernetes node ports etc.

  Cluster size can be increased using the scaling buttons for the node pool, or
  by modifying the node pool before the terraform deployment. 3 node clusters
  are a typical start for production environments, as explained in the course.

  For futher details, see also comments in the template file.
  FINISHED
}
