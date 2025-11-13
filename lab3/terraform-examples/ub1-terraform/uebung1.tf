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
  user_password = "<insert your password here>"
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
  #public_key = file("~/.ssh/id_rsa.pub")
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
# create instances
#
###########################################################################

resource "openstack_compute_instance_v2" "terraform-instance-1" {
  name              = "my-terraform-instance-1"
  image_name        = local.image_name
  flavor_name       = local.flavor_name
  key_pair          = openstack_compute_keypair_v2.terraform-keypair.name
  security_groups   = [openstack_networking_secgroup_v2.terraform-secgroup.name]

  depends_on = [openstack_networking_subnet_v2.terraform-subnet-1]

  network {
    uuid = openstack_networking_network_v2.terraform-network-1.id
  }

  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get -y install apache2
    rm /var/www/html/index.html
    cat > /var/www/html/index.html << INNEREOF
    <!DOCTYPE html>
    <html>
      <body>
        <h1>It works!</h1>
        <p>hostname</p>
      </body>
    </html>
    INNEREOF
    sed -i "s/hostname/terraform-instance-1/" /var/www/html/index.html
    sed -i "1s/$/ terraform-instance-1/" /etc/hosts
  EOF
}

resource "openstack_compute_instance_v2" "terraform-instance-2" {
  name            = "my-terraform-instance-2"
  image_name      = local.image_name
  flavor_name     = local.flavor_name
  key_pair        = openstack_compute_keypair_v2.terraform-keypair.name
  security_groups = [openstack_networking_secgroup_v2.terraform-secgroup.id]

  depends_on = [openstack_networking_subnet_v2.terraform-subnet-1]

  network {
    uuid = openstack_networking_network_v2.terraform-network-1.id
  }

  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get -y install apache2
    rm /var/www/html/index.html
    cat > /var/www/html/index.html << INNEREOF
    <!DOCTYPE html>
    <html>
      <body>
        <h1>It works!</h1>
        <p>hostname</p>
      </body>
    </html>
    INNEREOF
    sed -i "s/hostname/terraform-instance-2/" /var/www/html/index.html
    sed -i "1s/$/ terraform-instance-2/" /etc/hosts
  EOF
}



###########################################################################
#
# create load balancer
#
###########################################################################
resource "openstack_lb_loadbalancer_v2" "lb_1" {
  vip_subnet_id = openstack_networking_subnet_v2.terraform-subnet-1.id
}

resource "openstack_lb_listener_v2" "listener_1" {
  protocol        = "HTTP"
  protocol_port   = 80
  loadbalancer_id = openstack_lb_loadbalancer_v2.lb_1.id
  connection_limit = 1024
}

resource "openstack_lb_pool_v2" "pool_1" {
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.listener_1.id
}

resource "openstack_lb_members_v2" "members_1" {
  pool_id = openstack_lb_pool_v2.pool_1.id

  member {
    address       = openstack_compute_instance_v2.terraform-instance-1.access_ip_v4
    protocol_port = 80
  }

  member {
    address       = openstack_compute_instance_v2.terraform-instance-2.access_ip_v4
    protocol_port = 80
  }
}

resource "openstack_lb_monitor_v2" "monitor_1" {
  pool_id        = openstack_lb_pool_v2.pool_1.id
  type           = "HTTP"
  delay          = 5
  timeout        = 5
  max_retries    = 3
  http_method    = "GET"
  url_path       = "/"
  expected_codes = 200

  depends_on = [openstack_lb_loadbalancer_v2.lb_1, openstack_lb_listener_v2.listener_1, openstack_lb_pool_v2.pool_1, openstack_lb_members_v2.members_1 ]
}



###########################################################################
#
# assign floating ip to load balancer
#
###########################################################################
resource "openstack_networking_floatingip_v2" "fip_1" {
  pool    = local.pubnet_name
  port_id = openstack_lb_loadbalancer_v2.lb_1.vip_port_id
}

output "loadbalancer_vip_addr" {
  value = openstack_networking_floatingip_v2.fip_1
}
