# Minimalistic k3s deployment example for HS Fulda NetLab OpenStack

Start by cloning the repo.

```
git clone https://github.com/srieger1/internet-services-bsc-ai-examples.git
```

Go to the terraform/k3s-terraform folder and change the parameters in [main.tf](https://github.com/srieger1/internet-services-bsc-ai-examples/blob/main/terraform-examples/k3s-advanced-terraform/main.tf) to your username and password. Afterwards run:

```
terraform init
terraform apply
```

After terraform is finished you will get a floating IP of the k3s server. Login using the SSH key used for the deployment. kubectl is already installed. helm etc. needs to be installed. You can check:

```
kubectl get nodes
kubectl get pods -n kube-system
```

This is the advanced approach for k3s. It's installing helm/traefik with k3s. Also it's deploying 3 agents with 8gb RAM. You can change that config in locals at main.tf
