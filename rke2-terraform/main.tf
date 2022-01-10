module "controlplane" {
  source           = "remche/rke2/openstack"
  cluster_name     = var.cluster_name
  dns_servers      = var.dns_servers
  write_kubeconfig = true
  image_name       = "Ubuntu 20.04 - Focal Fossa - 64-bit - Cloud Based Image"
  flavor_name      = "m1.medium"
  public_net_name  = "public1"
  use_ssh_agent    = false
  ssh_key_file     = "/root/.ssh/id_rsa"
}
