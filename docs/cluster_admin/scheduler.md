# KubeVirt Scheduler
Scheduling is the process of matching Pods/VMs to Nodes. By default, the scheduler used is 
[kube-scheduler](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-scheduler/).
Further details can be found at [Kubernetes Scheduler Documentation](https://kubernetes.io/docs/concepts/scheduling-eviction/kube-scheduler/).

Custom schedulers can be used if the default scheduler does not satisfy your needs. For instance, you might want to schedule
VMs using a load aware scheduler such as [Trimaran Schedulers](https://cloud.redhat.com/blog/improving-the-resource-efficiency-for-openshift-clusters-via-trimaran-schedulers).

## Creating a Custom Scheduler
KubeVirt is compatible with custom schedulers. The configuration steps are described in the [Official Kubernetes 
Documentation](https://kubernetes.io/docs/tasks/extend-kubernetes/configure-multiple-schedulers).
Please note, the Kubernetes version KubeVirt is running on and the Kubernetes version used to build the custom
scheduler have to match.
To get the Kubernetes version KubeVirt is running on, you can run the following command:

```shell
$ kubectl version
Client Version: version.Info{Major:"1", Minor:"22", GitVersion:"v1.22.13", GitCommit:"a43c0904d0de10f92aa3956c74489c45e6453d6e", GitTreeState:"clean", BuildDate:"2022-08-17T18:28:56Z", GoVersion:"go1.16.15", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"22", GitVersion:"v1.22.13", GitCommit:"a43c0904d0de10f92aa3956c74489c45e6453d6e", GitTreeState:"clean", BuildDate:"2022-08-17T18:23:45Z", GoVersion:"go1.16.15", Compiler:"gc", Platform:"linux/amd64"}
```

Pay attention to the `Server` line. 
In this case, the Kubernetes version is `v1.22.13`.
You have to checkout the matching Kubernetes version and [build the Kubernetes project](https://kubernetes.io/docs/tasks/extend-kubernetes/configure-multiple-schedulers/#package-the-scheduler):

```shell
$ cd kubernetes
$ git checkout v1.22.13
$ make
```

Then, you can follow the configuration steps described [here](https://kubernetes.io/docs/tasks/extend-kubernetes/configure-multiple-schedulers/).
Additionally, the ClusterRole `system:kube-scheduler` needs permissions to use the verbs `watch`, `list` and `get` on StorageClasses.

```yaml
- apiGroups:                                                                                                   
  - storage.k8s.io                                                                                             
  resources:                                                                                                   
  - storageclasses                                                                                             
  verbs:                                                                                                       
  - watch                                                                                                      
  - list                                                                                                       
  - get 
```


## Scheduling VMs with the Custom Scheduler

The second scheduler should be up and running. You can check it with:

```shell
$ kubectl get all -n kube-system
```

The deployment `my-scheduler` should be up and running if everything is setup properly.
In order to launch the VM using the custom scheduler, you need to set the `SchedulerName` in the VM's spec to `my-scheduler`.
Here is an example VM definition:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: vm-fedora
spec:
  runStrategy: Always
  template:
    spec:
      schedulerName: my-scheduler
      domain:
        devices:
          disks:
            - name: containerdisk
              disk:
                bus: virtio
            - name: cloudinitdisk
              disk:
                bus: virtio
          rng: {}
        resources:
          requests:
            memory: 1Gi
      terminationGracePeriodSeconds: 180
      volumes:
        - containerDisk:
            image: quay.io/containerdisks/fedora:latest
          name: containerdisk
        - cloudInitNoCloud:
            userData: |-
              #cloud-config
              chpasswd:
                expire: false
              password: fedora
              user: fedora
          name: cloudinitdisk
```
In case the specified `SchedulerName` does not match any existing scheduler, the `virt-launcher` pod will stay in state
[Pending](https://kubernetes.io/docs/tasks/extend-kubernetes/configure-multiple-schedulers/#verifying-that-the-pods-were-scheduled-using-the-desired-schedulers), 
until the specified scheduler can be found.
You can check if the VM has been scheduled using the `my-scheduler` checking the `virt-launcher` pod events associated
with the VM. The pod should have been scheduled with `my-scheduler`.

```shell
$ kubectl get pods
NAME                             READY   STATUS    RESTARTS   AGE
virt-launcher-vm-fedora-dpc87    2/2     Running   0          24m

$ kubectl describe pod virt-launcher-vm-fedora-dpc87
[...] 
Events:
  Type    Reason     Age   From              Message
  ----    ------     ----  ----              -------
  Normal  Scheduled  21m   my-scheduler  Successfully assigned default/virt-launcher-vm-fedora-dpc87 to node01
[...]
```