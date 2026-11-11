## OpenStack credentials can be used in a more secure way by using
## cloud.yaml from https://private-cloud.informatik.hs-fulda.de/project/api_access/clouds.yaml/

# or by using env vars exported from openrc here,
# e.g., using 'export TF_VAR_os_password=$OS_PASSWORD'

# Define OpenStack credentials, project config etc.
locals {
  # values sourced from clouds.yaml in this directory
  cloud_config        = yamldecode(file("${path.module}/clouds.yaml"))["clouds"]["openstack"]
  auth_url            = local.cloud_config.auth.auth_url
  user_name           = local.cloud_config.auth.username
  region_name         = local.cloud_config.region_name
  #cacert_file         = "../../../os-trusted-cas"   # not needed now, using valid certificate
  object_store_url    = "https://s3.private-cloud.informatik.hs-fulda.de"

  router_name   = "${local.user_name}-router"
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
  ## enable AFTER the first apply has created the container and the
  ## EC2 credentials (see resources + output below), run
  ##   terraform output -json s3
  ## to get <access> and <secret>, then re-run
  ## 'terraform init' to migrate the local state to S3:
  ##   export AWS_ACCESS_KEY_ID=<access> AWS_SECRET_ACCESS_KEY=<secret>
  ##   terraform init
  #backend "s3" {
  #  skip_region_validation      = true
  #  skip_credentials_validation = true
  #  skip_metadata_api_check     = true
  #  skip_requesting_account_id  = true
  #  use_path_style              = true
  #  bucket             = "CloudServ17-lab3-docker-terraform-backend" # must match openstack_objectstorage_container_v1.terraform-backend
  #  key                = "terraform.tfstate"
  #  region             = "eu-central-1"
  #  endpoints = {
  #    s3 = "https://s3.private-cloud.informatik.hs-fulda.de/"
  #  }
  #}
}

# Configure the OpenStack Provider
provider "openstack" {
  cloud        = "openstack"
  #cacert_file = local.cacert_file
  #use_octavia = true # only needed for openstack provider <2.0
  # temporary fix to compensate keystone public endpoint still using 
  # a VIP with custom vault CA
  endpoint_overrides = {
    "identity" = local.auth_url 
  }
}



###########################################################################
#
# create terraform backend container and ec2 credentials 
#
###########################################################################

resource "openstack_objectstorage_container_v1" "terraform-backend" {
  name          = "${local.user_name}-lab3-docker-terraform-backend"
  force_destroy = true   # allows to delete backend container, but gives error, better: manual deletion
}

resource "openstack_identity_ec2_credential_v3" "s3" {
}

###########################################################################
#
# create keypair
#
###########################################################################

# import keypair, if public_key is not specified, create new keypair to use
resource "openstack_compute_keypair_v2" "terraform-keypair" {
  name       = "${local.user_name}-lab3-docker-pubkey"
  #public_key = file("~/.ssh/id_rsa.pub")
}



###########################################################################
#
# create security group
#
###########################################################################

resource "openstack_networking_secgroup_v2" "terraform-secgroup" {
  name        = "${local.user_name}-lab3-docker-secgroup"
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
  name           = "${local.user_name}-lab3-docker-network-1"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "terraform-subnet-1" {
  name            = "${local.user_name}-lab3-docker-subnet-1"
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

resource "openstack_compute_instance_v2" "terraform-docker-instance-1" {
  name              = "${local.user_name}-lab3-docker-instance-1"
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
    # see: https://docs.docker.com/engine/install/ubuntu/
    # also running the convenience script from https://get.docker.com/ or
    # https://github.com/docker/docker-install is possible, but risky
    apt-get install -y ca-certificates curl
    # install docker gpg key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    # add the repository to apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    # install docker
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    # post install
    #groupadd docker # already installed by package normally
    usermod -aG docker ubuntu # add default cloud image user to docker group
    # autostart docker on reboot
    systemctl enable docker.service
    systemctl enable containerd.service
    # start an example container
    docker run --restart unless-stopped --name nginx -d -p 80:80 nginx
    # see, https://hub.docker.com/_/nginx, also for docker-compose example etc.
  EOF
}



###########################################################################
#
# assign floating ip to instance 
#
###########################################################################
data "openstack_networking_port_v2" "port-1" {
  fixed_ip = openstack_compute_instance_v2.terraform-docker-instance-1.access_ip_v4
}

resource "openstack_networking_floatingip_v2" "fip_1" {
  pool    = local.pubnet_name
  port_id = data.openstack_networking_port_v2.port-1.id
}



###########################################################################
#
# output floating ip, s3 output contains sensitive information, only
# visible by running "terraform output -json s3"
#
###########################################################################
output "docker_vip_addr" {
  value = openstack_networking_floatingip_v2.fip_1
}

output "s3" {
  value = openstack_identity_ec2_credential_v3.s3
  sensitive = true
}
