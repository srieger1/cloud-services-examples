# Lab 6 - Monitoring & Observability

## Task 1: Extended terraform-openstack-rke2 hsfulda example to deploy monitoring and logging together with the wordpress "hello-world" example
* take a look at the example provided in this lab folder, especially take a look at the additional automatic helm chart installations monitoring.yaml, logging.yaml and wordpress.yaml in https://github.com/srieger1/cloud-services-examples/tree/main/lab6/hsfulda-example-monitoring/manifests

> [!TIP]
> How can the automatic helm chart installation in rke2 (see also, e.g., https://docs.k3s.io/add-ons/helm) be used to deploy also the CI/CD part or other applications?

## Task 2:
* deploy the additional manifests to your cluster or spin up a new cluster using the provided terraform files for the lab.
* you can add the installation of the charts by using, e.g., `kubectl apply -f monitoring.yaml` and remove them by using `kubectl delete -f monitoring.yaml`.

> [!TIP]
> To clean up later, you can also delete the namespace, e.g., using `kubectl delete namespace monitoring`. This will not only delete all k8s, but also all resources in OpenStack (except the storage volumes, as explained before, as these use the storage class "retain" by default) in a clean way, esp. load balancers, floating IPs etc.

## Task 3:
* get the password for grafana, e.g., by decoding the secret values in k9s or using:
  ```
  kubectl get secret --namespace monitoring -l app.kubernetes.io/component=admin-secret -o jsonpath="{.items[0].data.admin-password}" | base64 --decode ; echo
  kubectl get secret --namespace logging -l app.kubernetes.io/component=admin-secret -o jsonpath="{.items[0].data.admin-password}" | base64 --decode ; echo
  ```
* login to the monitoring grafana and observe the monitoring data, e.g., by taking a look at the CPU and memory footprint of the wordpress example
* configure loki in the separate grafana instance in the logging namespace
