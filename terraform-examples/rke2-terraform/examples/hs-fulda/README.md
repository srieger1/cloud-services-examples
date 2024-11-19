# HS-Fulda NetLab OpenStack RKE2 Example

This guide outlines the steps to set up an RKE2 Kubernetes cluster on OpenStack using Terraform, based on [this repository](https://github.com/zifeo/terraform-openstack-rke2). 🚀

## Attention

⚠️ This example uses provided CA certificates by default. Do not use this code in a production environment. ⚠️

## Usage

### Requirements

#### Linux

The final step fetches the `kubeconfig` file for Kubernetes clients like `kubectl` and `helm` automatically using `rsync` and `yq`. Note that `rsync` is typically pre-installed on most Linux distributions. Install `yq` from [here](https://github.com/mikefarah/yq/releases).

#### Windows

The final step requires `rsync` and `yq`, which are not available by default on Windows. You have multiple options to handle this (see the table below).

| Method                   | Description                                                                  | Commands/Instructions                                                                                                                                 |
| ------------------------ | ---------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| **SSH**                  | Manually log in and fetch `rke2.yaml` by assigning a temporary floating IP   | `ssh ubuntu@<floating-ip>`                                                                                                                            |
| **SCP**                  | Use `scp` to copy the `kubeconfig` file by assigning a temporary floating IP | `scp ubuntu@<floating-ip>:/etc/rancher/rke2/CloudComp<your-group-number>-k8s.rke2.yaml`                                                               |
| **WSL/WSL2**             | Use Windows Subsystem for Linux (WSL/WSL2) to run Terraform                  | Install `yq` from [here](https://github.com/mikefarah/yq/releases).                                                                                   |
| **Install rsync and yq** | Install `rsync` and `yq` on Windows                                          | Install `rsync` from [here](https://www.rsync.net/resources/howto/windows_rsync.html) and `yq` from [here](https://github.com/mikefarah/yq/releases). |

### Step 1: Clone the Repository

```sh
git clone https://github.com/srieger1/terraform-openstack-rke2.git
```

### Step 2: Configure Terraform Variables

Navigate to the `examples/hs-fulda` folder and create a `terraform.tfvars` file with your OpenStack credentials:

```hcl
project  = "CloudComp<your-group-number>"
username = "CloudComp<your-group-number>"
password = "<your-password>"
```

### Step 3: Initialize and Apply Terraform

Run the following commands inside the `examples/hs-fulda` folder:

```sh
terraform init
terraform apply
```

### Step 4: Fetch kubeconfig File

This step may take up to 10 minutes to complete as it involves setting up the cluster.

#### Linux Users

On Linux the `kubeconfig` file for Kubernetes clients like `kubectl` and `helm` is automatically fetched using `rsync` and `yq`. Note that `rsync` is typically pre-installed on most Linux distributions. Install `yq` from [here](https://github.com/mikefarah/yq/releases).

#### Windows Users

Since `rsync` and `yq` are not available by default on Windows, use one of the methods outlined in the table above to fetch the `kubeconfig` file.

### Step 5: Handle Deployment Issues

If any stages fail, rerun `terraform apply` to resume the deployment. If needed, modify cluster parameters (e.g., node count) in the `main.tf` file and rerun `terraform apply`.

### Step 6: Use Your Kubernetes Cluster

After deployment, set up your environment to use `kubectl`.

#### For Linux Users:

Set the `KUBECONFIG` environment variable:

```sh
export KUBECONFIG=CloudComp<your-group-number>-k8s.rke2.yaml
```

To continuously monitor the status of nodes and pods, use the `watch` command:

```sh
watch kubectl get nodes,pods -o wide -n kube-system
```

#### For Windows Users (PowerShell):

Set the `KUBECONFIG` environment variable:

```powershell
$env:KUBECONFIG = "CloudComp<your-group-number>-k8s.rke2.yaml"
```

To continuously monitor the status of nodes and pods, use the following loop in PowerShell:

```powershell
while ($true) {
    kubectl get nodes,pods -o wide -n kube-system
    Start-Sleep -Seconds 10
    Clear-Host
}
```

Within about four minutes, all pods should be running in the kube-system namespace. You can then deploy workloads, such as WordPress, using `helm`:

```sh
helm install my-release oci://registry-1.docker.io/bitnamicharts/wordpress
```

To check the deployment status:

#### For Linux:

```sh
watch kubectl get svc,pv,pvc,pods -o wide --namespace default
```

#### For Windows (PowerShell):

```powershell
while ($true) {
    kubectl get svc,pv,pvc,pods -o wide --namespace default
    Start-Sleep -Seconds 10
    Clear-Host
}
```

Access WordPress using the `EXTERNAL-IP` from the `my-release-wordpress` LoadBalancer service:

```sh
kubectl get svc -n default -w my-release-wordpress
```

The allocation of `EXTERNAL-IP` can take a few minutes.

### Step 7: Clean Up

Before running `terraform destroy`, delete any workloads:

```sh
helm uninstall my-release
terraform destroy
```
**If terraform destroy is stuck:**
Make sure that you delete the CSI volumes, load balancers with k8s in name, floating IPs, ports in the network, the subnet in the network, the network and the security groups created by the WordPress Helm Chart in OpenStack.

### Troubleshooting Tips

#### Describe Resources

Get detailed information about nodes, pods, services, or deployments:

```sh
kubectl describe <resource-type> <resource-name> -n <namespace>
```

Examples:

- Nodes: `kubectl describe nodes`
- Pods: `kubectl describe pod <pod-name> -n <namespace>`
- Services: `kubectl describe service <service-name> -n <namespace>`
- Deployments: `kubectl describe deployment <deployment-name> -n <namespace>`

#### Check Pod Logs

View logs of a specific pod. Note that a pod can have multiple containers. To find out which containers are running in a pod, use:

```sh
kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.spec.containers[*].name}'
```

Then, use the `-c <container-name>` option to specify a container if needed:

```sh
kubectl logs <pod-name> -n <namespace> -c <container-name>
```

#### Debug Pods

Open an interactive shell in a pod:

```sh
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh
```

These commands help diagnose and resolve issues in your Kubernetes cluster.

### Additional Resources

#### Learning Material

- **[Kubernetes Documentation](https://kubernetes.io/docs/home/):** Comprehensive guides and references for all aspects of Kubernetes.
- **[Kubernetes: The Documentary](https://www.youtube.com/watch?v=BE77h7dmoQU):** A video about the origins of Kubernetes.
- **[The Illustrated Children's Guide to Kubernetes](https://www.youtube.com/watch?v=4ht22ReBjno):** A fun, illustrated video explaining Kubernetes basics.
- **[Never install locally](https://www.youtube.com/watch?v=J0NuOlA2xDc):** A video that introduces the concepts of containerisation and orchestration.
- **[A Visual Guide on Troubleshooting Kubernetes Deployments](https://learnk8s.io/troubleshooting-deployments):** A visual guide to resolving common Kubernetes deployment issues.
- **[Zero to JupyterHub with Kubernetes](https://z2jh.jupyter.org/en/stable/):** A comprehensive guide to deploying and managing JupyterHub on Kubernetes. Great for learning with its step-by-step instructions and practical examples, suitable for both beginners and advanced users.

#### Useful tools

- **[Minikube](https://minikube.sigs.k8s.io/docs/):** A tool that enables you to run a local Kubernetes cluster.
- **[Kustomize](https://kustomize.io/):** A tool for managing Kubernetes objects through composition of bases and overlays.
- **[kubectx](https://github.com/ahmetb/kubectx):** For managing multiple Kubernetes clusters.
- **[k9s](https://github.com/derailed/k9s):** For an enhanced terminal-based UI for Kubernetes.
- **[Network Policy Editor](https://editor.networkpolicy.io/):** For easy editing of network policies.
- **[Argo CD](https://argoproj.github.io/cd/):** A declarative, GitOps-based continuous delivery tool for Kubernetes.
- **[Rancher](https://rancher.com/):** A complete Kubernetes management platform that simplifies cluster deployment and management.
- **[Podman](https://podman.io/):** A tool for managing OCI containers and pods, serving as an alternative to Docker.
