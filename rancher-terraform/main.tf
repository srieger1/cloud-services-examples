# Define IntServ group number
variable "group_number" {
  type = string
  default = "20"
}

## OpenStack credentials can be used in a more secure way by using
## cloud.yaml from https://private-cloud.informatik.hs-fulda.de/project/api_access/clouds.yaml/

# Define OpenStack credentials, project config etc.
locals {
  auth_url      = "https://private-cloud.informatik.hs-fulda.de:5000/v3"
  user_name     = "IntServ${var.group_number}"
  user_password = "IntServ.21"
  tenant_name   = "IntServ${var.group_number}"
  #network_name  = "IntServ${var.group_number}-net"
  router_name   = "IntServ${var.group_number}-router"
  image_name    = "Ubuntu 20.04 - Focal Fossa - 64-bit - Cloud Based Image"
  flavor_name   = "m1.medium"
  region_name   = "RegionOne"
}

# Define OpenStack provider
terraform {
required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = ">= 1.46.0"
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
  # public_key = file("~/srieger_rsa.pub")
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
    sudo docker run --privileged -d --restart=unless-stopped -p 80:80 -p 443:443 rancher/rancher
    sudo docker ps
    #sudo docker logs $(sudo docker ps | grep rancher | cut -d " " -f 1) 2>&1 | grep "Bootstrap Password:"
  EOF

  depends_on = [
    "openstack_networking_subnet_v2.terraform-rancher-subnet-1"
  ]
}



###########################################################################
#
# assign floating ip to load balancer
#
###########################################################################
resource "openstack_networking_floatingip_v2" "fip_1" {
  pool    = "public1"
}

resource "openstack_compute_floatingip_associate_v2" "fip_1" {
  floating_ip = "${openstack_networking_floatingip_v2.fip_1.address}"
  instance_id = "${openstack_compute_instance_v2.terraform-rancher-instance-1.id}"
}

output "floating_ip" {
  value = openstack_networking_floatingip_v2.fip_1
}
