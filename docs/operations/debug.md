# Debug
This page contains instructions on how to debug KubeVirt.

This is useful to both KubeVirt developers and advanced users that would like to gain deep understanding on what's
happening behind the scenes.

## Log Verbosity
KubeVirt produces a lot of logging throughout its codebase. Some log entries have a verbosity level defined to them.
The verbosity level that's defined for a log entry determines the minimum verbosity level in order to expose the
log entry.

In code, the log entry looks similar to: `log.Log.V(verbosity).Infof("...")` while `verbosity` is the minimum verbosity
level for this entry.

For example, if the log verbosity for some log entry is `3`, then the log would be exposed only if the log verbosity
is defined to be equal or greater than `3`, or else it would be filtered out.

Currently, log verbosity can be defined per-component or per-node. The most updated API is detailed [here](https://kubevirt.io/api-reference/master/definitions.html#_v1_logverbosity).

### Setting verbosity per KubeVirt component
One way of raising log verbosity is to manually determine it for the different components in `KubeVirt` CR:
```yaml
apiVersion: kubevirt.io/v1
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: kubevirt
spec:
  configuration:
    developerConfiguration:
      logVerbosity:
        virtLauncher: 2
        virtHandler: 3
        virtController: 4
        virtAPI: 5
        virtOperator: 6
```

This option is best for debugging specific components.

#### libvirt virtqemud.conf set log_filters according to virt-launcher log Verbosity

Verbosity level | log_filters in virtqemud.conf
-- | --
5 | log_filters="3:remote 4:event 3:util.json 3:util.object 3:util.dbus 3:util.netlink 3:node_device 3:rpc 3:access 3:util.threadjob 3:cpu.cpu 3:qemu.qemu_monitor 3:qemu.qemu_monitor_json 3:conf.domain_addr 1:*" |
6 | 3:remote 4:event 3:util.json 3:util.object 3:util.dbus 3:util.netlink 3:node_device 3:rpc 3:access 3:util.threadjob 3:cpu.cpu 3:qemu.qemu_monitor 1:*
7 | 3:remote 4:event 3:util.json 3:util.object 3:util.dbus 3:util.netlink 3:node_device 3:rpc 3:access 3:util.threadjob 3:cpu.cpu 1:*
8 and above | 3:remote 4:event 3:util.json 3:util.object 3:util.dbus 3:util.netlink 3:node_device 3:rpc 3:access 1:*

User can set self-defined log-filters via the annotations tag `kubevirt.io/libvirt-log-filters` in VMI configuration. e.g.
```yaml
kind: VirtualMachineInstance
metadata:
  name: my-vmi
  annotations:
    kubevirt.io/libvirt-log-filters: "3:remote 4:event 1:*"

```

### Setting verbosity per nodes
Another way is to set verbosity level per node:
```yaml
apiVersion: kubevirt.io/v1
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: kubevirt
spec:
  configuration:
    developerConfiguration:
      nodeVerbosity:
        "node01": 4
        "otherNodeName": 6
```

`nodeVerbosity` is essentially a map from string to int where the key is the node name and the value is the verbosity
level. The verbosity level would be defined for all the different components in that node (e.g. `virt-handler`,
`virt-launcher`, etc).

### How to retrieve KubeVirt components' logs
In Kubernetes, logs are defined at the Pod level. Therefore, first it's needed to list the Pods of KubeVirt's core
components. In order to do that we can first list the Pods under KubeVirt's install namespace.

For example:
```bash
$> kubectl get pods -n <KubeVirt Install Namespace>
NAME                               READY   STATUS    RESTARTS   AGE
disks-images-provider-7gqbc        1/1     Running   0          32m
disks-images-provider-vg4kx        1/1     Running   0          32m
virt-api-57fcc4497b-7qfmc          1/1     Running   0          31m
virt-api-57fcc4497b-tx9nc          1/1     Running   0          31m
virt-controller-76c784655f-7fp6m   1/1     Running   0          30m
virt-controller-76c784655f-f4pbd   1/1     Running   0          30m
virt-handler-2m86x                 1/1     Running   0          30m
virt-handler-9qs6z                 1/1     Running   0          30m
virt-operator-7ccfdbf65f-q5snk     1/1     Running   0          32m
virt-operator-7ccfdbf65f-vllz8     1/1     Running   0          32m
```

Then, we can pick one of the pods and fetch its logs. For example:
```bash
$> kubectl logs -n <KubeVirt Install Namespace> virt-handler-2m86x | head -n8
{"component":"virt-handler","level":"info","msg":"set verbosity to 2","pos":"virt-handler.go:453","timestamp":"2022-04-17T08:58:37.373695Z"}
{"component":"virt-handler","level":"info","msg":"set verbosity to 2","pos":"virt-handler.go:453","timestamp":"2022-04-17T08:58:37.373726Z"}
{"component":"virt-handler","level":"info","msg":"setting rate limiter to 5 QPS and 10 Burst","pos":"virt-handler.go:462","timestamp":"2022-04-17T08:58:37.373782Z"}
{"component":"virt-handler","level":"info","msg":"CPU features of a minimum baseline CPU model: map[apic:true clflush:true cmov:true cx16:true cx8:true de:true fpu:true fxsr:true lahf_lm:true lm:true mca:true mce:true mmx:true msr:true mtrr:true nx:true pae:true pat:true pge:true pni:true pse:true pse36:true sep:true sse:true sse2:true sse4.1:true ssse3:true syscall:true tsc:true]","pos":"cpu_plugin.go:96","timestamp":"2022-04-17T08:58:37.390221Z"}
{"component":"virt-handler","level":"warning","msg":"host model mode is expected to contain only one model","pos":"cpu_plugin.go:103","timestamp":"2022-04-17T08:58:37.390263Z"}
{"component":"virt-handler","level":"info","msg":"node-labeller is running","pos":"node_labeller.go:94","timestamp":"2022-04-17T08:58:37.391011Z"}

```

Obviously, for both examples above, `<KubeVirt Install Namespace>` needs to be replaced with the actual namespace
KubeVirt is installed in.


## KubeVirt PProf Profiler
Using the `cluster-profiler` client tool, a developer can get the PProf profiling data for every component in the Kubevirt Control plane. Here is a user guide:

### Compile `cluster-profiler`
Build from source code
```
$ git clone https://github.com/kubevirt/kubevirt.git
$ cd kubevirt/tools/cluster-profiler
$ go build
```

### Enable the feature gate
Add `ClusterProfiler` in KubeVirt config
```
$ cat << END > enable-feature-gate.yaml

---
apiVersion: kubevirt.io/v1
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: kubevirt
spec:
  configuration:
    developerConfiguration:
      featureGates:
        - ClusterProfiler
END

$ kubectl apply -f enable-feature-gate.yaml
```

### Do the profiling
Start CPU profiling
```
$ cluster-profiler --cmd start

2023/05/17 09:31:09 SUCCESS: started cpu profiling KubeVirt control plane
```
Stop CPU profiling
```
$ cluster-profiler --cmd stop

2023/05/17 09:31:14 SUCCESS: stopped cpu profiling KubeVirt control plane
```
Dump the pprof result
```
$ cluster-profiler --cmd dump

2023/05/17 09:31:18 Moving already existing "cluster-profiler-results" => "cluster-profiler-results-old-67fq"
SUCCESS: Dumped PProf 6 results for KubeVirt control plane to [cluster-profiler-results]
```
The PProf result can be found in the folder `cluster-profiler-results`
```
$ tree cluster-profiler-results

cluster-profiler-results
├── virt-api-5f96f84dcb-lkpb7
│   ├── allocs.pprof
│   ├── block.pprof
│   ├── cpu.pprof
│   ├── goroutine.pprof
│   ├── heap.pprof
│   ├── mutex.pprof
│   └── threadcreate.pprof
├── virt-controller-5bbd9554d9-2f8j2
│   ├── allocs.pprof
│   ├── block.pprof
│   ├── cpu.pprof
│   ├── goroutine.pprof
│   ├── heap.pprof
│   ├── mutex.pprof
│   └── threadcreate.pprof
├── virt-controller-5bbd9554d9-qct2w
│   ├── allocs.pprof
│   ├── block.pprof
│   ├── cpu.pprof
│   ├── goroutine.pprof
│   ├── heap.pprof
│   ├── mutex.pprof
│   └── threadcreate.pprof
├── virt-handler-ccq6c
│   ├── allocs.pprof
│   ├── block.pprof
│   ├── cpu.pprof
│   ├── goroutine.pprof
│   ├── heap.pprof
│   ├── mutex.pprof
│   └── threadcreate.pprof
├── virt-operator-cdc677b7-pg9j2
│   ├── allocs.pprof
│   ├── block.pprof
│   ├── cpu.pprof
│   ├── goroutine.pprof
│   ├── heap.pprof
│   ├── mutex.pprof
│   └── threadcreate.pprof
└── virt-operator-cdc677b7-pjqdx
    ├── allocs.pprof
    ├── block.pprof
    ├── cpu.pprof
    ├── goroutine.pprof
    ├── heap.pprof
    ├── mutex.pprof
    └── threadcreate.pprof
```
