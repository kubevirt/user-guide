DNS for Services and VirtualMachineInstances
============================================

Creating unique DNS entries per VirtualMachineInstance
------------------------------------------------------

In order to create unique DNS entries per VirtualMachineInstance, it is
possible to set `spec.hostname` and `spec.subdomain`. If a subdomain is
set and a headless service with a name, matching the subdomain, exists,
kube-dns will create unique DNS entries for every VirtualMachineInstance
which matches the selector of the service. Have a look at the [DNS for
Services and Pods
documentation](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#pods-hostname-and-subdomain-fields)
for additional information.

The following example consists of a VirtualMachine and a headless
Service which matches the labels and the subdomain of the
VirtualMachineInstance:

    apiVersion: kubevirt.io/v1alpha3
    kind: VirtualMachineInstance
    metadata:
      name: vmi-fedora
      labels:
        expose: me
    spec:
      hostname: "myvmi"
      subdomain: "mysubdomain"
      domain:
        devices:
          disks:
          - disk:
              bus: virtio
            name: containerdisk
          - disk:
              bus: virtio
            name: cloudinitdisk
        resources:
          requests:
            memory: 1024M
      terminationGracePeriodSeconds: 0
      volumes:
      - name: containerdisk
        containerDisk:
          image: kubevirt/fedora-cloud-registry-disk-demo:latest
      - cloudInitNoCloud:
          userDataBase64: IyEvYmluL2Jhc2gKZWNobyAiZmVkb3JhOmZlZG9yYSIgfCBjaHBhc3N3ZAo=
        name: cloudinitdisk
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: mysubdomain
    spec:
      selector:
        expose: me
      clusterIP: None
      ports:
      - name: foo # Actually, no port is needed.
        port: 1234
        targetPort: 1234

As a consequence, when we enter the VirtualMachineInstance via e.g.
`virtctl console vmi-fedora` and ping `myvmi.mysubdomain` we see that we
find a DNS entry for `myvmi.mysubdomain.default.svc.cluster.local` which
points to `10.244.0.57`, which is the IP of the VirtualMachineInstance
(not of the Service):

    [fedora@myvmi ~]$ ping myvmi.mysubdomain
    PING myvmi.mysubdomain.default.svc.cluster.local (10.244.0.57) 56(84) bytes of data.
    64 bytes from myvmi.mysubdomain.default.svc.cluster.local (10.244.0.57): icmp_seq=1 ttl=64 time=0.029 ms
    [fedora@myvmi ~]$ ip a
    2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
        link/ether 0a:58:0a:f4:00:39 brd ff:ff:ff:ff:ff:ff
        inet 10.244.0.57/24 brd 10.244.0.255 scope global dynamic eth0
           valid_lft 86313556sec preferred_lft 86313556sec
        inet6 fe80::858:aff:fef4:39/64 scope link
           valid_lft forever preferred_lft forever

So `spec.hostname` and `spec.subdomain` get translated to a DNS A-record
of the form
`<vmi.spec.hostname>.<vmi.spec.subdomain>.<vmi.metadata.namespace>.svc.cluster.local`.
If no `spec.hostname` is set, then we fall back to the
VirtualMachineInstance name itself. The resulting DNS A-record looks
like this then:
`<vmi.metadata.name>.<vmi.spec.subdomain>.<vmi.metadata.namespace>.svc.cluster.local`.
