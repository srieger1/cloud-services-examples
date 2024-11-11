# Consider using 'export TF_VAR_os_auth_url=$OS_AUTH_URL'
variable "os_auth_url"{}
# Consider using 'export TF_VAR_os_password=$OS_PASSWORD'
variable "os_password"{}

 module "rke" {
  source  = "remche/rke/openstack"
  image_name             = "Ubuntu 20.04 - Focal Fossa - 64-bit - Cloud Based Image"
  public_net_name        = "public1"
  master_flavor_name     = "m1.small"
  worker_flavor_name     = "m1.small"
  os_auth_url            = var.os_auth_url
  os_password            = var.os_password
  #use_ssh_agent          = false
  #enable_loadbalancer    = true
  #use_octavia            = true
  wait_for_commands      = ["while docker info ; [ $? -ne 0 ]; do echo wait for docker; sudo newgrp - docker ; sleep 30 ; done"]
  user_data_file         = "user-data.sh"
  dns_servers            = [ "192.168.76.253" ]
}
