# Lab 4 - Orchestration with Kubernetes (k8s)

## Task 1: Install Kubernetes in our OpenStack private cloud
* clone the following repo and use hs-fulda example from https://github.com/srieger1/terraform-openstack-rke2/tree/hsfulda-example/examples/hs-fulda to deploy RKE2 in our OpenStack, the README contains instructions, esp. necessary for windows to get the k8s credentials (kubeconfig, rke2.yaml)
* configure main.tf and take a look at the `module` directive. See its source in the main directory of the repo https://github.com/srieger1/terraform-openstack-rke2/tree/hsfulda-example.

> [!TIP]
> * How can terraform modules be used? What is the role of the tf files in the main folder of the repo? What is the role of the tf in the node folder? What role do the manifests and patches folders play? 

## Task 2:
* use terraform to spin up an RKE2 cluster with one controller and one worker
* retrieve the kubeconfig and use kubectl and k9s to take a look at your k8s cluster (nodes, namespaces, pods, svc etc.).
* take a look at the OpenStack resources coming up, see different subnets being used and see server groups being created for anti-affinity of workers in the compute section.
* deploy the nginx example provided here: https://github.com/prona-p4-learning-platform/cc-container/tree/main/labs/lab1

> [!TIP]
> * Discuss the pros and cons of Kubernetes and how it compares and integrates with cloud providers like OpenStack and container ecosystems like docker.
> * Why is it called container orchestration? Why is Kubernetes so popular in the recent years? Why is it related to cloud-native?

> [!TIP]
> When using Windows in the lab, the easiest method to access rke2 and k8s is to login to the controller and use it as a deployment host.
> `ssh ubuntu@<floating-ip>` displayed in the output of terraform as soon as it complains that it does not find rsync and yq on Windows.
> Afterwards you can use the following commands on the controller to access and use k8s or deploy the wordpress example:

```bash
# make kubeconfig / credentials readable for user
# set env var to allow kubectl, helm, k9s etc. to find and access rke2 k8s
chmod 666 /etc/rancher/rke2/rke2.yaml
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml

# k9s installation (https://k9scli.io/)
https://github.com/derailed/k9s/releases/download/v0.50.16/k9s_Linux_amd64.tar.gz
./k9s
# helm installation (https://helm.sh/de/docs/intro/install)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash
helm
helm install my-release oci://registry-1.docker.io/bitnamicharts/wordpress
```

See also the README for the hsfulda example in https://github.com/srieger1/terraform-openstack-rke2/blob/hsfulda-example/examples/hs-fulda/README.md

---

Break

---

## Task 3:
* deploy wordpress as a sample workload to Kubernetes using helm (see the [README](https://github.com/srieger1/terraform-openstack-rke2/blob/hsfulda-example/examples/hs-fulda/README.md) for hs-fulda example or https://artifacthub.io/packages/helm/bitnami/wordpress
* watch the storage volumes and load balancer being created in OpenStack, e.g., using the web interface (horizon)
* access wordpress and take a look at the options for the helm chart deployment
* kill one of the wordpress pods and see it getting recreated
* undeploy wordpress and make sure that storage volumes and load balancer are deleted in OpenStack

> [!CAUTION]
> You must uninstall the helm chart to delete the load balancer and storage volumes for wordpress in OpenStack to be deleted
> before destroying the cluster! volumes are even retained by default and you have to delete them manually - that's intentionally the default

* destroy the cluster using `terraform destroy`

> [!TIP]
> * Why is terraform unable to delete storage volumes and load balancer created in OpenStack if `helm uninstall` was not executed?
> * How can Kubernetes provide a reproducible, dependable and scalable infrastructure for applications and services?

## Task 4:
* try to understand the concept and content of the helm chart https://github.com/bitnami/charts/tree/main/bitnami/wordpress)
* see the structure of the chart in `Chart.yaml`. Take a look at the configuration options in `values.yaml`.

> [!TIP]
> * What is the role of `deployment.yaml`, `svc.yaml`, `_helpers.tpl` and `NOTES.txt` in the templates folder?
> * What are the pros and cons of application deployments, e.g., using helm in k8s?

## Task 5:
* Kubernetes resources deep-dive: take a look at logs of pods, enter a shell in a pod/container. Take a look at svc. Try to see and scale a ReplicaSet for a deployment and its pods. Describe and edit a pod and deployment.
