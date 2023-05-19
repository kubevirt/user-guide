# Managing KubeVirt with GitOps

The GitOps way uses Git repositories as a single source of truth to deliver
infrastructure as code. Automation is employed to keep the desired and the live
state of clusters in sync at all times. This means any change to a repository
is automatically applied to one or more clusters while changes to a cluster will
be automatically reverted to the state described in the single source of truth.

With GitOps the separation of testing and production environments, improving
the availability of applications and working with multi-cluster environments
becomes considerably easier.

## Demo repository

A demo with detailed explanation on how to manage KubeVirt with GitOps can be
found [here](https://github.com/0xFelix/gitops-demo).

The demo is using [Open Cluster Management](https://open-cluster-management.io/)
and [ArgoCD](https://argoproj.github.io/cd/) to deploy KubeVirt and virtual 
machines across multiple clusters.