# Define IntServ group number
variable "group_number" {
  type = string
  default = "20"
}

## OpenStack credentials can be used in a more secure way by using
## cloud.yaml from https://private-cloud.informatik.hs-fulda.de/project/api_access/clouds.yaml/

# or by using env vars exported from openrc here,
# e.g., using 'export TF_VAR_os_password=$OS_PASSWORD'

# Define OpenStack credentials, project config etc.
locals {
  auth_url      = "https://private-cloud.informatik.hs-fulda.de:5000/v3"
  user_name     = "IntServ${var.group_number}"
  user_password = "<password of your group here, private-cloud is only reachable via vpn>"
  tenant_name   = "IntServ${var.group_number}"
  #network_name  = "IntServ${var.group_number}-net"
  router_name   = "IntServ${var.group_number}-router"
  image_name    = "Ubuntu 20.04 - Focal Fossa - 64-bit - Cloud Based Image"
  flavor_name   = "m1.small"
  region_name   = "RegionOne"
  floating_net  = "public1"
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
resource "openstack_compute_keypair_v2" "terraform-k3s-keypair" {
  name       = "my-terraform-k3s-pubkey"
  public_key = file("~/.ssh/id_ed25519.pub")
}



###########################################################################
#
# create security group
#
###########################################################################

resource "openstack_networking_secgroup_v2" "terraform-k3s-secgroup" {
  name        = "my-terraform-k3s-secgroup"
  description = "for terraform k3s instances"
}

resource "openstack_networking_secgroup_rule_v2" "terraform-k3s-secgroup-rule-k8s" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  #remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.terraform-k3s-secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "terraform-k3s-secgroup-rule-ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  #remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.terraform-k3s-secgroup.id
}


###########################################################################
#
# create network
#
###########################################################################

resource "openstack_networking_network_v2" "terraform-k3s-network-1" {
  name           = "my-terraform-k3s-network-1"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "terraform-k3s-subnet-1" {
  name            = "my-terraform-k3s-subnet-1"
  network_id      = openstack_networking_network_v2.terraform-k3s-network-1.id
  cidr            = "192.168.255.0/24"
  ip_version      = 4
  dns_nameservers = ["192.168.76.253"]
}

data "openstack_networking_router_v2" "router-1" {
  name = local.router_name
}

resource "openstack_networking_router_interface_v2" "router_interface_1" {
  router_id = data.openstack_networking_router_v2.router-1.id
  subnet_id = openstack_networking_subnet_v2.terraform-k3s-subnet-1.id
}

data "openstack_networking_network_v2" "fip_network" {
  name = local.floating_net
}

resource "openstack_networking_floatingip_v2" "fip_1" {
  pool = local.floating_net
}



###########################################################################
#
# create instances
#
###########################################################################

resource "openstack_compute_instance_v2" "k3s-server-1" {
  name              = "k3s-server-1"
  image_name        = local.image_name
  flavor_name       = local.flavor_name
  key_pair          = openstack_compute_keypair_v2.terraform-k3s-keypair.name
  security_groups   = [openstack_networking_secgroup_v2.terraform-k3s-secgroup.name]

  depends_on = [openstack_networking_subnet_v2.terraform-k3s-subnet-1]

  network {
    uuid = openstack_networking_network_v2.terraform-k3s-network-1.id
  }

  user_data = <<-EOF
    #cloud-config
    #packages_update: true
    #packages_upgrade: true
    packages:
      - htop
    write_files:
      - path: /run/cloud-config
        content: |
          [Global]
          #docu: https://github.com/kubernetes/cloud-provider-openstack
          #source: https://raw.githubusercontent.com/kubernetes/cloud-provider-openstack/master/manifests/controller-manager/cloud-config
          auth-url=${local.auth_url}
          #Tip: You can also use Application Credential ID and Secret in place of username, password, tenant-id, and domain-id.
          #application-credential-id=
          #application-credential-secret=
          username=${local.user_name}
          # user-id=
          password=${local.user_password}
          region=${local.region_name}
          tenant-id=
          domain-id=
          
          [LoadBalancer]
          subnet-id=${openstack_networking_subnet_v2.terraform-k3s-subnet-1.id}
          floating-network-id=${data.openstack_networking_network_v2.fip_network.id}
    bootcmd:
      - [ cloud-init-per, once, first-boot, touch, /run/first-boot-timestamp ]
    #runcmd:
    #  - curl -sfL https://get.k3s.io | K3S_TOKEN="this-is-not-a-secure-token" sh -s - server --disable-cloud-controller --disable=servicelb --kubelet-arg="cloud-provider=external" --node-external-ip ${openstack_networking_floatingip_v2.fip_1.address}
    runcmd:
      - curl -sfL https://get.k3s.io | K3S_TOKEN="this-is-not-a-secure-token" sh -s - server --disable-cloud-controller --disable servicelb --disable=traefik --kubelet-arg="cloud-provider=external" --node-external-ip ${openstack_networking_floatingip_v2.fip_1.address}
  EOF
}

resource "openstack_compute_instance_v2" "k3s-agent-1" {
  name            = "k3s-agent-1"
  image_name      = local.image_name
  flavor_name     = local.flavor_name
  key_pair        = openstack_compute_keypair_v2.terraform-k3s-keypair.name
  security_groups = [openstack_networking_secgroup_v2.terraform-k3s-secgroup.id]

  depends_on = [openstack_networking_subnet_v2.terraform-k3s-subnet-1]

  network {
    uuid = openstack_networking_network_v2.terraform-k3s-network-1.id
  }

  user_data = <<-EOF
    #cloud-config
    #packages_update: true
    #packages_upgrade: true
    packages:
      - htop
    bootcmd:
      - [ cloud-init-per, once, first-boot, touch, /run/first-boot-timestamp ]
    runcmd:
      - curl -sfL https://get.k3s.io | K3S_URL=https://${openstack_compute_instance_v2.k3s-server-1.access_ip_v4}:6443 K3S_TOKEN="this-is-not-a-secure-token" sh -
  EOF
}



###########################################################################
#
# assign floating ip to server instance
#
###########################################################################
resource "openstack_compute_floatingip_associate_v2" "fip_1" {
  floating_ip = "${openstack_networking_floatingip_v2.fip_1.address}"
  instance_id = "${openstack_compute_instance_v2.k3s-server-1.id}"
}

output "loadbalancer_vip_addr" {
  value = openstack_networking_floatingip_v2.fip_1
}
