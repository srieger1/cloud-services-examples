# Lab 5 - CI/CD GitOps with GitHub Actions & Argo CD

## Task 1: Demo: Calendar Application
* take a look at the example application provided in https://github.com/faizananwar532/hsfulda-argocd-demo, project structure, features and tech stack are described in the README
* see the docker-compose.yml to understand which services are deployed

> [!TIP]
> * How does docker-compose compare to our previous k8s deployment? What are the benefits and drawbacks of docker-compose?

## Task 2:
* take a look at the helm chart provided in the `calendar-chart` directory.

## Taks 3:
* install Argo CD in your RKE2 k8s cluster as desribed in the main repo https://github.com/faizananwar532/hsfulda-argocd-demo/blob/main/README.md.
* access and configure ArgoCD as described in the argocd-setup folder https://github.com/faizananwar532/hsfulda-argocd-demo/tree/main/argocd-setup

> [!IMPORTANT]
> * as discussed in the lab on 4.12.2025, Bitnami images previously used in the hsfulda-argocd-demo were removed from the registry by Broadcom and are not publically available anymore!
> * as a fix thankfully some students provide a new repo that uses other freely available container images: https://github.com/7reax/hsfulda-argocd-demo/tree/main
> * another option that a group of students used to fix the issue is to use the Argo CD quick start demos and deployed the guestbook example https://github.com/argoproj/argocd-example-apps/tree/master/guestbook as also described in https://argo-cd.readthedocs.io/en/stable/getting_started/

> [!TIP]
> * What are the benefits of GitOps using CI/CD tools like Argo CD or Flux CD?
> * Discuss the pros and cons of Kubernetes for CI/CD like Argo CD or Flux CD
