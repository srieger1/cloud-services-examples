# Define IntServ group number
variable "group_number" {
  type = string
  default = "<INSERT YOUR GROUP NUMBER HERE>"
}

## OpenStack credentials can be used in a more secure way by using
## cloud.yaml from https://private-cloud.informatik.hs-fulda.de/project/api_access/clouds.yaml/

# or by using env vars exported from openrc here,
# e.g., using 'export TF_VAR_os_password=$OS_PASSWORD'

# Define OpenStack credentials, project config etc.
locals {
  auth_url      = "https://private-cloud.informatik.hs-fulda.de:5000/v3"
  user_name     = "CloudServ${var.group_number}"
  user_password = "<INSERT YOUR PASSWORD HERE>"
  tenant_name   = "CloudServ${var.group_number}"
  cacert_file   = "./os-trusted-cas"
  region_name   = "RegionOne"

  router_name   = "CloudServ${var.group_number}-router"
  dns_servers   = [ "10.33.16.100", "8.8.8.8" ]

  pubnet_name   = "ext_net"
  image_name    = "ubuntu-22.04-jammy-server-cloud-image-amd64"

  server_flavor_name  = "m1.medium"
  agent_flavor_name   = "m1.large"
}

# Define OpenStack provider
terraform {
required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = ">= 3.0.0"
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
  cacert_file = local.cacert_file
}



###########################################################################
#
# create keypair
#
###########################################################################

# import keypair, if public_key is not specified, create new keypair to use
resource "openstack_compute_keypair_v2" "terraform-k3s-keypair" {
  name       = "my-terraform-k3s-pubkey"
#  public_key = file("~/.ssh/chrisLaptop.pub")
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
  dns_nameservers = local.dns_servers
}

data "openstack_networking_router_v2" "router-1" {
  name = local.router_name
}

resource "openstack_networking_router_interface_v2" "router_interface_1" {
  router_id = data.openstack_networking_router_v2.router-1.id
  subnet_id = openstack_networking_subnet_v2.terraform-k3s-subnet-1.id
}

data "openstack_networking_network_v2" "fip_network" {
  name = local.pubnet_name
}

###########################################################################
#
# create floating IP and associate to port
#
###########################################################################

resource "openstack_networking_port_v2" "k3s_server_port" {
  name           = "k3s-server-0-port"
  network_id     = openstack_networking_network_v2.terraform-k3s-network-1.id
  admin_state_up = "true"
  security_group_ids = [openstack_networking_secgroup_v2.terraform-k3s-secgroup.id]

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.terraform-k3s-subnet-1.id
  }
}

resource "openstack_networking_floatingip_v2" "fip_1" {
  pool    = local.pubnet_name
  port_id = openstack_networking_port_v2.k3s_server_port.id
}

###########################################################################
#
# create instances
#
###########################################################################

resource "openstack_compute_instance_v2" "k3s-server-0" {
  name              = "k3s-server-0"
  image_name        = local.image_name
  flavor_name       = local.server_flavor_name
  key_pair          = openstack_compute_keypair_v2.terraform-k3s-keypair.name
  security_groups   = [openstack_networking_secgroup_v2.terraform-k3s-secgroup.name]

  depends_on = [openstack_networking_subnet_v2.terraform-k3s-subnet-1]

  network {
    port = openstack_networking_port_v2.k3s_server_port.id
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
      - curl -sfL https://get.k3s.io | K3S_TOKEN="this-is-not-a-secure-token" sh -s - server --disable-cloud-controller --disable servicelb --write-kubeconfig-mode 644 --kubelet-arg="cloud-provider=external" --node-external-ip ${openstack_networking_floatingip_v2.fip_1.address}
      - sudo mkdir /home/ubuntu/.kube
      - sudo cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
      - curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
      - chmod 700 get_helm.sh
      - ./get_helm.sh
      - export KUBECONFIG=/home/ubuntu/.kube/config
 EOF
}

resource "openstack_compute_instance_v2" "k3s-agent" {
  count 	  = 3
  name            = "k3s-agent-${count.index}"
  image_name      = local.image_name
  flavor_name     = local.agent_flavor_name
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
      - curl -sfL https://get.k3s.io | K3S_URL=https://${openstack_compute_instance_v2.k3s-server-0.access_ip_v4}:6443 K3S_TOKEN="this-is-not-a-secure-token" sh -
  EOF
}


############################################################################
# assign floating ip to server instance
#
###########################################################################

output "loadbalancer_vip_addr" {
  value = openstack_networking_floatingip_v2.fip_1.address
}
