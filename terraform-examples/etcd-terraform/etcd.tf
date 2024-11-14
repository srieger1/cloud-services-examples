# Define CloudServ group number
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
  user_name     = "CloudServ${var.group_number}"
  user_password = "<password of your group here, private-cloud is only reachable via vpn>"
  tenant_name   = "CloudServ${var.group_number}"
  cacert_file   = "./os-trusted-cas"
  region_name   = "RegionOne"

  router_name   = "CloudServ${var.group_number}-router"
  dns_servers   = [ "10.33.16.100", "8.8.8.8" ]

  pubnet_name   = "ext_net"

  image_name    = "ubuntu-22.04-jammy-server-cloud-image-amd64"
  flavor_name   = "m1.small"
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
  cacert_file = local.cacert_file
  #use_octavia = true # only needed for openstack provider <2.0
}



###########################################################################
#
# create keypair
#
###########################################################################

# import keypair, if public_key is not specified, create new keypair to use
resource "openstack_compute_keypair_v2" "terraform-keypair" {
  name       = "my-terraform-pubkey"
  public_key = file("~/.ssh/id_rsa.pub")
}



###########################################################################
#
# create security group
#
###########################################################################

resource "openstack_networking_secgroup_v2" "terraform-secgroup" {
  name        = "my-terraform-secgroup"
  description = "for terraform instances"
}

resource "openstack_networking_secgroup_rule_v2" "terraform-secgroup-rule-http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  #remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.terraform-secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "terraform-secgroup-rule-ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  #remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.terraform-secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "terraform-secgroup-rule-etcd-external" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 2379 
  port_range_max    = 2379
  #remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.terraform-secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "terraform-secgroup-rule-etcd-internal" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 2380 
  port_range_max    = 2380
  #remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.terraform-secgroup.id
}



###########################################################################
#
# create network
#
###########################################################################

resource "openstack_networking_network_v2" "terraform-network-1" {
  name           = "my-terraform-network-1"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "terraform-subnet-1" {
  name            = "my-terraform-subnet-1"
  network_id      = openstack_networking_network_v2.terraform-network-1.id
  cidr            = "192.168.255.0/24"
  ip_version      = 4
  dns_nameservers = local.dns_servers
}

data "openstack_networking_router_v2" "router-1" {
  name = local.router_name
}

resource "openstack_networking_router_interface_v2" "router_interface_1" {
  router_id = data.openstack_networking_router_v2.router-1.id
  subnet_id = openstack_networking_subnet_v2.terraform-subnet-1.id
}



###########################################################################
#
# create ports 
#
###########################################################################

resource "openstack_networking_port_v2" "port_etcd-1" {
  name           = "port_etcd-1"
  network_id     = openstack_networking_network_v2.terraform-network-1.id
  admin_state_up = "true"

  fixed_ip {
    subnet_id    = openstack_networking_subnet_v2.terraform-subnet-1.id
  }
}

resource "openstack_networking_port_v2" "port_etcd-2" {
  name           = "port_etcd-2"
  network_id     = openstack_networking_network_v2.terraform-network-1.id
  admin_state_up = "true"

  fixed_ip {
    subnet_id    = openstack_networking_subnet_v2.terraform-subnet-1.id
  }
}

resource "openstack_networking_port_v2" "port_etcd-3" {
  name           = "port_etcd-3"
  network_id     = openstack_networking_network_v2.terraform-network-1.id
  admin_state_up = "true"

  fixed_ip {
    subnet_id    = openstack_networking_subnet_v2.terraform-subnet-1.id
  }
}



###########################################################################
#
# create instances
#
###########################################################################

resource "openstack_compute_servergroup_v2" "terraform-etcd-servergroup-1" {
  name     = "terraform-etcd-servergroup-1"
  policies = ["soft-anti-affinity"]
}

resource "openstack_compute_instance_v2" "terraform-etcd-instance-1" {
  name              = "my-terraform-etcd-instance-1"
  image_name        = local.image_name
  flavor_name       = local.flavor_name
  key_pair          = openstack_compute_keypair_v2.terraform-keypair.name
  security_groups   = [openstack_networking_secgroup_v2.terraform-secgroup.name]

  depends_on = [openstack_networking_subnet_v2.terraform-subnet-1]

  scheduler_hints {
    group = openstack_compute_servergroup_v2.terraform-etcd-servergroup-1.id
  }

  network {
    port = openstack_networking_port_v2.port_etcd-1.id
  }

  user_data = <<-EOF
    #!/bin/bash

    # installation from https://github.com/etcd-io/etcd/releases/

    ETCD_VER=v3.4.34

    # choose either URL
    GOOGLE_URL=https://storage.googleapis.com/etcd
    GITHUB_URL=https://github.com/etcd-io/etcd/releases/download
    DOWNLOAD_URL=$GOOGLE_URL

    rm -f /tmp/etcd-$ETCD_VER-linux-amd64.tar.gz
    rm -rf /tmp/etcd-download-test && mkdir -p /tmp/etcd-download-test

    curl -L $DOWNLOAD_URL/$ETCD_VER/etcd-$ETCD_VER-linux-amd64.tar.gz -o /tmp/etcd-$ETCD_VER-linux-amd64.tar.gz
    tar xzvf /tmp/etcd-$ETCD_VER-linux-amd64.tar.gz -C /tmp/etcd-download-test --strip-components=1
    rm -f /tmp/etcd-$ETCD_VER-linux-amd64.tar.gz

    /tmp/etcd-download-test/etcd --version
    /tmp/etcd-download-test/etcdctl version

    /tmp/etcd-download-test/etcd --name infra1 --initial-advertise-peer-urls http://${openstack_networking_port_v2.port_etcd-1.all_fixed_ips[0]}:2380 \
      --listen-peer-urls http://${openstack_networking_port_v2.port_etcd-1.all_fixed_ips[0]}:2380 \
      --listen-client-urls http://${openstack_networking_port_v2.port_etcd-1.all_fixed_ips[0]}:2379,http://127.0.0.1:2379 \
      --advertise-client-urls http://${openstack_networking_port_v2.port_etcd-1.all_fixed_ips[0]}:2379 \
      --initial-cluster-token etcd-cluster-1 \
      --initial-cluster infra1=http://${openstack_networking_port_v2.port_etcd-1.all_fixed_ips[0]}:2380,infra2=http://${openstack_networking_port_v2.port_etcd-2.all_fixed_ips[0]}:2380,infra3=http://${openstack_networking_port_v2.port_etcd-3.all_fixed_ips[0]}:2380 \
      --initial-cluster-state new

    # example: write,read to etcd
    #/tmp/etcd-download-test/etcdctl --endpoints=localhost:2379 put foo bar
    #/tmp/etcd-download-test/etcdctl --endpoints=localhost:2379 get foo

  EOF
}

resource "openstack_compute_instance_v2" "terraform-etcd-instance-2" {
  name              = "my-terraform-etcd-instance-2"
  image_name        = local.image_name
  flavor_name       = local.flavor_name
  key_pair          = openstack_compute_keypair_v2.terraform-keypair.name
  security_groups   = [openstack_networking_secgroup_v2.terraform-secgroup.name]

  depends_on = [openstack_networking_subnet_v2.terraform-subnet-1]

  scheduler_hints {
    group = openstack_compute_servergroup_v2.terraform-etcd-servergroup-1.id
  }

  network {
    port = openstack_networking_port_v2.port_etcd-2.id
  }

  user_data = <<-EOF
    #!/bin/bash

    # installation from https://github.com/etcd-io/etcd/releases/

    ETCD_VER=v3.4.34

    # choose either URL
    GOOGLE_URL=https://storage.googleapis.com/etcd
    GITHUB_URL=https://github.com/etcd-io/etcd/releases/download
    DOWNLOAD_URL=$GOOGLE_URL

    rm -f /tmp/etcd-$ETCD_VER-linux-amd64.tar.gz
    rm -rf /tmp/etcd-download-test && mkdir -p /tmp/etcd-download-test

    curl -L $DOWNLOAD_URL/$ETCD_VER/etcd-$ETCD_VER-linux-amd64.tar.gz -o /tmp/etcd-$ETCD_VER-linux-amd64.tar.gz
    tar xzvf /tmp/etcd-$ETCD_VER-linux-amd64.tar.gz -C /tmp/etcd-download-test --strip-components=1
    rm -f /tmp/etcd-$ETCD_VER-linux-amd64.tar.gz

    /tmp/etcd-download-test/etcd --version
    /tmp/etcd-download-test/etcdctl version

    /tmp/etcd-download-test/etcd --name infra2 --initial-advertise-peer-urls http://${openstack_networking_port_v2.port_etcd-2.all_fixed_ips[0]}:2380 \
      --listen-peer-urls http://${openstack_networking_port_v2.port_etcd-2.all_fixed_ips[0]}:2380 \
      --listen-client-urls http://${openstack_networking_port_v2.port_etcd-2.all_fixed_ips[0]}:2379,http://127.0.0.1:2379 \
      --advertise-client-urls http://${openstack_networking_port_v2.port_etcd-2.all_fixed_ips[0]}:2379 \
      --initial-cluster-token etcd-cluster-1 \
      --initial-cluster infra1=http://${openstack_networking_port_v2.port_etcd-1.all_fixed_ips[0]}:2380,infra2=http://${openstack_networking_port_v2.port_etcd-2.all_fixed_ips[0]}:2380,infra3=http://${openstack_networking_port_v2.port_etcd-3.all_fixed_ips[0]}:2380 \
      --initial-cluster-state new

    # example: write,read to etcd
    #/tmp/etcd-download-test/etcdctl --endpoints=localhost:2379 put foo bar
    #/tmp/etcd-download-test/etcdctl --endpoints=localhost:2379 get foo

  EOF
}

resource "openstack_compute_instance_v2" "terraform-etcd-instance-3" {
  name              = "my-terraform-etcd-instance-3"
  image_name        = local.image_name
  flavor_name       = local.flavor_name
  key_pair          = openstack_compute_keypair_v2.terraform-keypair.name
  security_groups   = [openstack_networking_secgroup_v2.terraform-secgroup.name]

  depends_on = [openstack_networking_subnet_v2.terraform-subnet-1]

  scheduler_hints {
    group = openstack_compute_servergroup_v2.terraform-etcd-servergroup-1.id
  }

  network {
    port = openstack_networking_port_v2.port_etcd-3.id
  }

  user_data = <<-EOF
    #!/bin/bash

    # installation from https://github.com/etcd-io/etcd/releases/

    ETCD_VER=v3.4.34

    # choose either URL
    GOOGLE_URL=https://storage.googleapis.com/etcd
    GITHUB_URL=https://github.com/etcd-io/etcd/releases/download
    DOWNLOAD_URL=$GOOGLE_URL

    rm -f /tmp/etcd-$ETCD_VER-linux-amd64.tar.gz
    rm -rf /tmp/etcd-download-test && mkdir -p /tmp/etcd-download-test

    curl -L $DOWNLOAD_URL/$ETCD_VER/etcd-$ETCD_VER-linux-amd64.tar.gz -o /tmp/etcd-$ETCD_VER-linux-amd64.tar.gz
    tar xzvf /tmp/etcd-$ETCD_VER-linux-amd64.tar.gz -C /tmp/etcd-download-test --strip-components=1
    rm -f /tmp/etcd-$ETCD_VER-linux-amd64.tar.gz

    /tmp/etcd-download-test/etcd --version
    /tmp/etcd-download-test/etcdctl version

    /tmp/etcd-download-test/etcd --name infra3 --initial-advertise-peer-urls http://${openstack_networking_port_v2.port_etcd-3.all_fixed_ips[0]}:2380 \
      --listen-peer-urls http://${openstack_networking_port_v2.port_etcd-3.all_fixed_ips[0]}:2380 \
      --listen-client-urls http://${openstack_networking_port_v2.port_etcd-3.all_fixed_ips[0]}:2379,http://127.0.0.1:2379 \
      --advertise-client-urls http://${openstack_networking_port_v2.port_etcd-3.all_fixed_ips[0]}:2379 \
      --initial-cluster-token etcd-cluster-1 \
      --initial-cluster infra1=http://${openstack_networking_port_v2.port_etcd-1.all_fixed_ips[0]}:2380,infra2=http://${openstack_networking_port_v2.port_etcd-2.all_fixed_ips[0]}:2380,infra3=http://${openstack_networking_port_v2.port_etcd-3.all_fixed_ips[0]}:2380 \
      --initial-cluster-state new

    # example: write,read to etcd
    #/tmp/etcd-download-test/etcdctl --endpoints=localhost:2379 put foo bar
    #/tmp/etcd-download-test/etcdctl --endpoints=localhost:2379 get foo

  EOF
}



###########################################################################
#
# assign floating ip to instances 
#
###########################################################################

resource "openstack_networking_floatingip_v2" "fip_1" {
  pool    = local.pubnet_name
  port_id = openstack_networking_port_v2.port_etcd-1.id
}

resource "openstack_networking_floatingip_v2" "fip_2" {
  pool    = local.pubnet_name
  port_id = openstack_networking_port_v2.port_etcd-2.id
}

resource "openstack_networking_floatingip_v2" "fip_3" {
  pool    = local.pubnet_name
  port_id = openstack_networking_port_v2.port_etcd-3.id
}

output "etcd-1_vip_addr" {
  value = openstack_networking_floatingip_v2.fip_1.address
}

output "etcd-2_vip_addr" {
  value = openstack_networking_floatingip_v2.fip_2.address
}

output "etcd-3_vip_addr" {
  value = openstack_networking_floatingip_v2.fip_3.address
}

