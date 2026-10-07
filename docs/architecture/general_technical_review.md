# General Technical Review - KubeVirt / Incubation

!!! note
    This document was created as part of a CNCF initiative and a requirement for 
    projects to move between levels. It was originally created as part of the process
    for KubeVirt to graduate. It is intended to be a living document, however it is not
    expected to be updated for every release. Similarly, the [General Technical Review
    template](https://github.com/cncf/toc/blob/main/toc_subprojects/project-reviews-subproject/general-technical-questions.md) maintained by the CNCF is expected to evolve.
    
    Please pay attention to the `Date updated` and `Template version` metadata.
    
    If you notice disparities or inconsistencies, please feel welcome to raise an issue 
    or PR to have this corrected.
    

- **Project: KubeVirt**
- **Project Version: 1.4** 
- **Website: kubevirt.io**
- **Date Updated:** 2025-01-24
- **Template Version:** v1.0
- **Description:** KubeVirt is an open-source project that extends Kubernetes to enable the management of virtual machines (VMs) alongside containerized workloads. It provides seamless integration with Kubernetes API using a custom resource definition (CRD). Users can leverage Kubernetes capabilities for both traditional and containerized workloads in a cloud-native environment.


## Day 0 - Planning Phase

### Scope

  * Describe the roadmap process, how scope is determined for mid to long term features, as well as how the roadmap maps back to current contributions and maintainer ladder?

  The roadmap of the KubeVirt project is shaped by contributions from the community. Prioritized work items are being derived from the community-submitted proposals in the kubevirt/community repo. We also document our [upcoming changes](https://github.com/kubevirt/sig-release/blob/main/upcoming-changes.md) in our sig-release repo to show what will likely be in our next version of KubeVirt.  
  The enhancement framework provides a standardized way to propose and track features via issues and community reviews.  
  Approved enhancement proposals drive priorities and guide contributions and code reviews.  
  The roadmap supports the maintainer ladder by giving contributors opportunities to grow through impactful work on governance, prioritized features, encouraging new contributors, and review efforts.

* Describe the target persona or user(s) for the project?

  The target audience of KubeVirt includes infrastructure owners, platform engineers, DevOps teams, and application developers who require running and orchestrating virtual machines alongside containers using Kubernetes, bridging legacy and cloud-native workloads within a unified platform.

* Explain the primary use case for the project. What additional use cases are supported by the project?

  The primary use case for KubeVirt is enabling organizations to manage and orchestrate virtual machines (VMs) alongside containerized workloads in Kubernetes clusters. This is particularly valuable for hybrid environments where legacy applications require VMs, while modern applications are containerized, allowing unified management and application integration through Kubernetes APIs and workflows.

  **Additional Use Cases:**
  
  * **Infrastructure Modernization:**  
    Gradually transitioning from traditional virtualization platforms to cloud-native infrastructures without disrupting existing VM workloads.
  
  * **Hybrid Application Architectures:**  
    Supporting applications that combine VM-based components (e.g., databases) with containerized workloads.
  
  * **Development and Testing Environments:**  
    Providing developers a Kubernetes-native way to create, test, and run VM-based workloads in CI/CD pipelines.
  
  * **Edge Computing:**  
    Managing VMs on edge devices for workloads that require dedicated resources or specific operating system environments.
  
  * **Isolation:**  
    Combination of containerized workloads and VMs with a higher level of isolation.
  
  * **Multi-tenancy:**  
    VMs serving Kubernetes clusters or VMs being used as nodes in virtual Kubernetes clusters.

* Explain which use cases have been identified as unsupported by the project.

  * “Delta Cloud” like abstraction. Thus having the KubeVirt APIs being a single API to different cloud platforms, such as hyperscalers.
  * Supporting other than KVM hypervisors and qemu virtual machine monitor (VMM) runtimes. However, the project remains open to ideas.

* Describe the intended types of organizations who would benefit from adopting this project. (i.e., financial services, any software manufacturer, organizations providing platform engineering services)?

  KubeVirt would benefit organizations that operate in hybrid environments or are looking to modernize their infrastructure and bridge traditional and cloud-native technologies.  
  Organizations with the requirement to run internal private clouds of mixed VM and container workloads or are planning to adopt mixed workloads in the future.  
  Due to the ubiquity of virtualization in IT, KubeVirt is not tied to any specific market segment.

* Please describe any completed end user research and link to any reports.

  There have been no end user studies around KubeVirt that we are aware of.


### Usability

### Usability

* How should the target personas interact with your project?

  VM owners and cluster admins alike - users of the project - should interact with KubeVirt primarily through Kubernetes native and KubeVirt-specific APIs and/or CLI.

* Describe the user experience (UX) and user interface (UI) of the project.

  Usability-wise, KubeVirt tries to adopt Kubernetes UX and API patterns in order to provide a “unified” user experience for users - regardless of whether or not they are working with virtual machines or containers.

  There is no official KubeVirt user interface. However, there are a couple of user interfaces provided by platform vendors, such as:
  
  * SUSE Virtualization
  * Red Hat OpenShift Virtualization
  * Deckhouse (Virtualization)
  * KubeVirt Manager (community project)

* Describe how this project integrates with other projects in a production environment.

  **Kubernetes** - KubeVirt extends Kubernetes by introducing custom resource definitions (CRDs) like VirtualMachine and VirtualMachineInstance. These resources integrate directly into Kubernetes workflows. Users can manage VMs using Kubernetes-native APIs.

  **Prometheus** - KubeVirt components expose Prometheus-compatible endpoints, Alerts, and runbooks in order to integrate well with this monitoring solution.

  **Medik8s** - KubeVirt community members contributed to Medik8s in order to add high-availability support for bare-metal Kubernetes clusters, supporting KubeVirt’s use case.

  **ovn-kubernetes** and **kubernetes-ovn** - KubeVirt contributors contributed to both projects to allow them to seamlessly integrate with KubeVirt virtual machines. Additional work is done for CNI plugins to be used with multus for better secondary network support.

  **Istio** - KubeVirt contributors provided patches to Istio in order to integrate KubeVirt VMs out of the box with Istio.

  **ArgoCD** - KubeVirt contributors provided patches to Argo in order to align with common Argo practices.

  **Tekton** - KubeVirt maintains a set of Tekton tasks in order to easily build Tekton Pipelines around VMs.

  **Velero** - KubeVirt contributors integrate Velero into KubeVirt in order to support third-party backup vendors.

  **cluster-api-kubevirt** - Cluster API KubeVirt is built on KubeVirt.

  **Kubernetes descheduler** - KubeVirt community members contributed several changes to the Kubernetes descheduler in order to let the descheduler work seamlessly with VMs as well.

  **kubernetes-nmstate** - KubeVirt community members contributed to kubernetes-nmstate to provide a declarative approach for host network configuration—a common problem in bare-metal clusters.

  **multus** - KubeVirt leverages Multus APIs in order to implement secondary networks for VMs.

  And others like Kubernetes itself, AAQ, CRI-O.

### Design

* Explain the design principles and best practices the project is following.  

  KubeVirt prioritizes integration with and the usability experience of Kubernetes. It takes advantage of Kubernetes native APIs, CRDs (Custom Resource Definitions), and core primitives and patterns to manage VMs as first-class citizens.  

  Here is more information on KubeVirt Architecture and guiding principles, especially the KubeVirt Razor:  
  "If something is useful for Pods, we should not implement it for VMs only".

* Outline or link to the project’s architecture requirements? Describe how they differ for Proof of Concept, Development, Test and Production environments, as applicable.  

  KubeVirt works from single-node setup all the way up to large scale Kubernetes clusters with hundreds of nodes.  
  For production workloads, the primary requirement is to provide bare metal nodes.  

  All the details can be found at [KubeVirt Installation Guide](https://kubevirt.io/user-guide/cluster_admin/installation/)

* Define any specific service dependencies the project relies on in the cluster.  

  KubeVirt requires Kubernetes to be present, nothing else.  
  The cluster should have bare metal nodes if production workloads are planned to be run.

* Describe how the project implements Identity and Access Management.  

  KubeVirt leverages Kubernetes' native Identity and Access Management (IAM) capabilities to control access to resources and operations related to virtual machines (VMs).

* Describe how the project has addressed sovereignty.  

  KubeVirt depends on the Kubernetes community but operates an independent community outside of the Kubernetes SIGs. This includes but is not limited to its own [SIG/Subproject/WG structure](https://github.com/kubevirt/community/blob/main/sig-list.md).

* Describe any compliance requirements addressed by the project.  

  The project is not actively pursuing any compliance effort.  
  However, some of the vendors that distribute KubeVirt do.

* Describe the project’s High Availability requirements.  

  KubeVirt implements best practices for High Availability using replication for its control-plane resources.  
  It’s also supporting the project (medik8s) in order to add high availability to the Kubernetes cluster it runs and depends on.

* Describe the project’s resource requirements, including CPU, Network and Memory.  

  KubeVirt’s resource requirements depend on the end user’s scale requirements. A good estimate is around 1 CPU and 1GB of memory. The network requirements are the same for KubeVirt as Kubernetes.  

  In the end, the resource requirements depend on the scale of the environment. Some dimensions of the scale are node count, VM count, and disk count.  
  Members of the KubeVirt community are operating KubeVirt on single-node deployments, up to clusters with hundreds of nodes.

* Describe the project’s storage requirements, including its use of ephemeral and/or persistent storage.  

  KubeVirt shares the same storage requirements as Kubernetes. The end user defines what storage is required for their workloads, and KubeVirt will use Kubernetes APIs to use what is defined.

* Please outline the project’s API Design  

  KubeVirt is a Kubernetes API extension defined by Custom Resource Definitions. KubeVirt’s philosophy is to re-use Kubernetes APIs for defining infrastructure. Then, KubeVirt will make the infrastructure resources available to Virtual Machines.

  * Describe the project’s API topology and conventions  

    KubeVirt’s API is RESTful and declarative, following precedents set by Kubernetes as much as possible.

  * Describe the project defaults  

    KubeVirt provides configuration defaults, allowing users to “just” deploy KubeVirt without requiring any input.

  * Outline any additional configurations from default to make reasonable use of the project  

    KubeVirt has one default configuration that it shares between KubeVirt components.

  * Describe any new or changed API types and calls - including to cloud providers - that will result from this project being enabled and used  

    Most KubeVirt APIs are Kubernetes API extensions (CRDs). They are documented at [KubeVirt API Reference](http://kubevirt.io/api-reference/)

  * Describe compatibility of any new or changed APIs with API servers, including the Kubernetes API server  

    Compatibility is provided in [KubeVirt Kubernetes Compatibility](https://github.com/kubevirt/kubevirt/blob/main/docs/kubernetes-compatibility.md)

  * Describe versioning of any new or changed APIs, including how breaking changes are handled  

    For releases, KubeVirt follows Semantic Versioning - just like Kubernetes does.  
    For CRDs, KubeVirt follows Kubernetes standards for API versioning to ensure stability, compatibility, and a clear evolution of its APIs.  
    KubeVirt APIs are versioned with labels such as v1alpha1, v1beta1, and v1 - where alpha is considered experimental, beta is more stable with some backward compatibility, and v1 is a fully mature API with strong backward compatibility guarantees.  
    KubeVirt v1 APIs maintain backward compatibility, and changes that are not backward compatible are avoided in stable APIs.

* Describe the project’s release processes, including major, minor and patch releases.  

  The release process is described in [KubeVirt Release Guide](https://github.com/kubevirt/kubevirt/blob/main/docs/release.md)


### Installation

* Describe how the project is installed and initialized, e.g. a minimal install with a few lines of code or does it require more complex integration and configuration?  

  KubeVirt is providing an Operator for deployment and application life-cycle management. Alternatively, deployment can be manually performed by installing key components from the kubevirt and containerized-data-importer repositories.   These are all installed using `kubectl`.

  There are then additional optional network plugins that can be installed.

  Reference: https://kubevirt.io/user-guide/cluster_admin/installation/#installing-kubevirt-on-kubernetes

* How does an adopter test and validate the installation?

  An adopter can run the KubeVirt testsuite on their deployment.

### Security

* Please provide a link to the project’s cloud native [security self assessment](https://github.com/cncf/tag-security/blob/main/community/assessments/guide/self-assessment.md).

  The self assessment is in progress and tracked at [https://github.com/kubevirt/community/issues/335](https://github.com/kubevirt/community/issues/335).  
  This document will be updated pointing to the self-assessment once it is completed.

* Please review the [Cloud Native Security Tenets](https://github.com/cncf/tag-security/blob/main/security-whitepaper/secure-defaults-cloud-native-8.md) from TAG Security.
  * How are you satisfying the tenets of cloud native security projects?  
    Currently there are no processes in place in order to enforce the tenets of cloud native security.

  * Describe how each of the cloud native principles apply to your project.  
    TBD  
    Possible link: [Cloud Native Principles](https://github.com/cloud-native-principles/cloud-native-principles/blob/master/cloud-native-principles.md)

  * How do you recommend users alter security defaults in order to "loosen" the security of the project? Please link to any documentation the project has written concerning these use cases.  
    [KubeVirt Security Fundamentals](https://kubevirt.io/2020/KubeVirt-Security-Fundamentals.html)

### Security Hygiene

* Please describe the frameworks, practices, and procedures the project uses to maintain the basic health and security of the project.  
  While there is no formal framework for ensuring security practices, discussing security is part of the PR review process.

* Describe how the project has evaluated which features will be a security risk to users if they are not maintained by the project?  
  The KubeVirt maintainers acknowledge the risk of unmaintained code and features for end users.  
  A structural change in order to address this challenge is to require every piece of code to be owned and maintained by a KubeVirt SIG.  
  If a piece of code is not accepted by a SIG then it cannot land in KubeVirt, as it bears the risk of becoming unmaintained, and thus a security risk.

### Cloud Native Threat Modeling

* Explain the least minimal privileges required by the project and reasons for additional privileges.  
  By design, KubeVirt VMs are designed to work with the restricted PSL.  
  There is also the design principle that a user must not gain any additional privileges or permissions when running a VM compared to any other pod the user could run.

  Special privileges are only granted to infrastructure components such as virt-handler (the node agent).

* Describe how the project is handling certificate rotation and mitigates any issues with certificates.  
  “In KubeVirt both our CA and certificates are rotated on a user-defined recurring interval.  
  In the event that either the CA key or a certificate is compromised, this information will eventually be rendered stale and unusable regardless of whether the compromise is known or not.  
  If the compromise is known, a forced CA and certificate rotation can be invoked by the cluster admin simply by deleting the corresponding secrets in the KubeVirt install namespace.”  
  - [KubeVirt Security Fundamentals](https://kubevirt.io/2020/KubeVirt-Security-Fundamentals.html)

* Describe how the project is following and implementing [secure software supply chain best practices](https://project.linuxfoundation.org/hubfs/CNCF_SSCP_v1.pdf)  
  While there is no active work by the community to implement SSSC best practices, there are recurring discussions of how to get this on track.

## Day 1 \- Installation and Deployment Phase

### Project Installation and Configuration

* Describe what project installation and configuration look like.
     
  This is described in 
  https://kubevirt.io/user-guide/cluster_admin/installation/#installing-kubevirt-on-kubernetes

### Project Enablement and Rollback

* How can this project be enabled or disabled in a live cluster? Please describe any downtime required of the control plane or nodes.  

  After deploying the KubeVirt operator, this is as simple as deploying the KubeVirt CR - or removing it for uninstallation.

* Describe how enabling the project changes any default behavior of the cluster or running workloads.

  KubeVirt installation adds virtualization capabilities to a Kubernetes cluster, allowing the users to manage and run virtual machines. Although the default behavior and existing workloads should not be impacted, it introduces new   resources and components to support VMs.
  The cluster-configuration  - i.e. API server configuration - itself is not modified by KubeVirt.  

* Describe how the project tests enablement and disablement.  

  Installing and uninstalling KubeVirt is part of the KubeVirt testsuite.

* How does the project clean up any resources created, including CRDs?

  KubeVirt is using an operator for application life-cycle management. This operator is removing all KubeVirt related components.
  KubeVirt related CRDs are deleted with `kubectl delete -f kubevirt.yaml` all associated resources will be deleted. 

  All the details are documented in: https://kubevirt.io/user-guide/cluster_admin/updating_and_deletion/#deleting-kubevirt



### Rollout, Upgrade and Rollback Planning

* How does the project intend to provide and maintain compatibility with infrastructure and orchestration management tools like Kubernetes and with what frequency?  

  KubeVirt has a defined compatibility matrix:
  https://github.com/kubevirt/kubevirt/blob/main/docs/kubernetes-compatibility.md
    
  In addition, KubeVirt is - by itself - a cloud native application, delivered completely in containers, ensuring a strong separation from the underlying infrastructure.

  https://kubevirt.io/user-guide/cluster_admin/updating_and_deletion/#updating-and-deletion

* Describe how the project handles rollback procedures.  

  KubeVirt is designed to roll forward only. Feature development, bug fixes, and testing are aligned to this objective.
  However, technically it is possible to rollback.

* How can a rollout or rollback fail? Describe any impact to already running workloads.  

  Running workloads are not immediately impacted by a failed rollout or rollback. Workloads - just like Kubernetes - will keep running for a while.
  Depending on the failure and environment - workloads will continue to run for long, or eventually be impacted by rippled issues in the cluster.

* Describe any specific metrics that should inform a rollback.  

  The KubeVirt Operator’s “Ready” condition is staying in “false”.

* Explain how upgrades and rollbacks were tested and how the upgrade-\>downgrade-\>upgrade path was tested.

  Upgrade testing is part of pre-submit testing.
  Rollbacks and up- → down- → upgrade testing is not covered.

* Explain how the project informs users of deprecations and removals of features and APIs.

  KubeVirt is currently using API v1 and has maintained a strict commitment to not removing existing API constructs. Any feature that has been considered for removal has been restricted by an opt-in FeatureGate. Removal of any such   feature is discussed on the KubeVirt development mailing list well in advance.

* Explain how the project permits utilization of alpha and beta capabilities as part of a rollout.

  KubeVirt’s feature lifecycle uses the Kubernetes model. Features are initially implemented using alpha version strings in the API and are feature gated. Features then graduate to beta and the feature gate is removed as part of the   release lifecycle.

## Day 2 \- Day-to-Day Operations Phase

### Scalability/Reliability

* Describe how the project increases the size or count of existing API objects.

  KubeVirt is a Kubernetes cloud native application leveraging core Kube entities at runtime.
  While the exact numbers depend on the cluster size, it is in the ballpark of tens of pods, tens of secrets, some deployment, and a daemonset.

  In general KubeVirt is considered to have a small footprint compared to the cluster where it is expected to be running on.

  There will be some etcd load induced according to the number of running VMs.

* Describe how the project defines Service Level Objectives (SLOs) and Service Level Indicators (SLIs).  

  KubeVirt does not describe any SLO or SLI.


* Describe any operations that will increase in time covered by existing SLIs/SLOs.  

  N/A

* Describe the increase in resource usage in any components as a result of enabling this project, to include CPU, Memory, Storage, Throughput.  

  There is an increased resource usage.
  Depending on the cluster and workload size it is recommended to maintain dedicated infra nodes, or just keep sufficient spare capacity on the cluster.

* Describe which conditions enabling / using this project would result in resource exhaustion of some node resources (PIDs, sockets, inodes, etc.)  


  Every VM is run in it’s own pod. Due to this usually all limits that relate to pods apply to VMs as well.

* Describe the load testing that has been performed on the project and the results. 

  KubeVirt project is doing regular performance and load testing as part of SIG scale.

  Vendors like Red Hat perform regular performance and scale tests as part of their productization.

* Describe the recommended limits of users, requests, system resources, etc. and how they were obtained.

  Limits on number of VMs or number of nodes is not only determined by the project, but also by how the underlying cluster is operated.

  Highly optimized organizations can easily go to tens of thousands of VMs on a single cluster with hundreds of nodes.
  Regular users are recommended to adjust their cluster size to operational models and requirements.

  A regular - large - KubeVirt cluster is expected to host thousands of VMs on less than 100 nodes.

* Describe which resilience pattern the project uses and how, including the circuit breaker pattern.

### Observability Requirements

* Describe the signals the project is using or producing, including logs, metrics, profiles and traces. Please include supported formats, recommended configurations and data storage.

  KubeVirt is providing metric endpoints, and shipping Prometheus alert rules including runbooks.
  KubeVirt is also consistently using error conditions on it’s CRs.

* Describe how the project captures audit logging.

  The Kubernetes audit log can be used for KubeVirt, as all user-facing API calls go through the Kubernetes API server.

* Describe any dashboards the project uses or implements as well as any dashboard requirements.

  KubeVirt does not implement any dashboard.
  There are some community maintained grafana dashboards available.

* Describe how the project surfaces project resource requirements for adopters to monitor cloud and infrastructure costs, e.g. FinOps  

  Adopters just need to continue to monitor their Kubernetes usage.

* Which parameters is the project covering to ensure the health of the application/service and its workloads?  

  KubeVirt allows to set health checks for the workloads.
  The KubeVirt operator is checking the health of it’s infra components.
  The KubeVirt Operator health (including it’s dependents) is also reported via a prometheus endpoint.

* How can an operator determine if the project is in use by workloads?  

  KubeVirt is providing the ability to run virtual machine workloads. Those run in pods. Thus the same mechanism for monitoring pods can be used for monitoring VMs.

* How can someone using this project know that it is working for their instance?  

  They can look at the KubeVirt Operator conditions. If it’s not working, then a condition will be set.

* Describe the SLOs (Service Level Objectives) for this project.

  There are no SLOs defined.

* What are the SLIs (Service Level Indicators) an operator can use to determine the health of the service?

  There are no SLIs defined.

### Dependencies

* Describe the specific running services the project depends on in the cluster.

  KubeVirt relies on Kubernetes only, with no other mandatory dependencies. KubeVirt can optionally work in harmony with the Containerized Data Importer and nmstate projects.

* Describe the project’s dependency lifecycle policy.

  KubeVirt is written in golang and uses go.mod/go.sum to track dependencies added to the build chain. Each dependency added is vetted during the code review/submission process.

* How does the project incorporate and consider source composition analysis as part of its development and security hygiene? Describe how this source composition analysis (SCA) is tracked.

  KubeVirt uses FOSSA to ensure compliance with security and license requirements. These checks are applied to every pull request for the project.

* Describe how the project implements changes based on source composition analysis (SCA) and the timescale.

  FOSSA checks are applied to every pull request. Additionally, KubeVirt periodically leverages SonarCloud to detect commonly problematic code patterns.

### Troubleshooting

* How does this project recover if a key component or feature becomes unavailable? e.g Kubernetes API server, etcd, database, leader node, etc.  

  If the cluster control plane is lost. The workload will remain to run. They will try to periodically reconnect with the cluster control plane.


* Describe the known failure modes.

  The cluster API goes down: Workloads continue to run. KubeVirt control plane will recover eventually.
  The node/kubelet goes down: Workloads will go down. KubeVirt will reschedule the workloads on other nodes if possible

### Security

* Security Hygiene
  * How is the project executing access control?

    KubeVirt relies on Kubernetes access control and is not performing access control by itself.

* Cloud Native Threat Modeling  

  Cloud Native Threat Modeling has not been performed yet for KubeVirt.

  * How does the project ensure its security reporting and response team is representative of its community diversity (organizational and individual)?  

    It’s a best effort by the KubeVirt maintainers to keep multiple organizations involved in security reporting, security response teams, and auditing efforts.

  * How does the project invite and rotate security reporting team members?

    The project relies on vendors to perform this rotation.
