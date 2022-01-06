# Guest Agent information

Guest Agent (GA) is an optional component that can run inside of Virtual Machines.
The GA provides plenty of additional runtime information about the running operating system (OS).
More technical detail about available GA commands is available [here](https://qemu.weilnetz.de/doc/3.1/qemu-ga-ref.html).


## Guest Agent info in Virtual Machine status

GA presence in the Virtual Machine is signaled with a condition in the VirtualMachineInstance status.
The condition tells that the GA is connected and can be used.

GA condition on VirtualMachineInstance

    status:
      conditions:
      - lastProbeTime: "2020-02-28T10:22:59Z"
        lastTransitionTime: null
        status: "True"
        type: AgentConnected


When the GA is connected, additional OS information is shown in the status.
This information comprises:

   - guest info, which contains OS runtime data
   - interfaces info, which shows QEMU interfaces merged with GA interfaces info.

Below is the example of the information shown in the VirtualMachineInstance status.

GA info with merged into status

    status:
      guestOSInfo:
        id: fedora
        kernelRelease: 4.18.16-300.fc29.x86_64
        kernelVersion: '#1 SMP Sat Oct 20 23:24:08 UTC 2018'
        name: Fedora
        prettyName: Fedora 29 (Cloud Edition)
        version: "29"
        versionId: "29"
      interfaces:
      - infoSource: domain, guest-agent
        interfaceName: eth0
        ipAddress: 10.244.0.23/24
        ipAddresses:
        - 10.244.0.23/24
        - fe80::858:aff:fef4:17/64
        mac: 0a:58:0a:f4:00:17
        name: default

When the Guest Agent is not present in the Virtual Machine, the Guest Agent information is not shown. No error is reported because the Guest Agent is an optional component.

The infoSource field indicates where the info is gathered from. Valid values:

   - domain: the info is based on the domain spec
   - guest-agent: the info is based on Guest Agent report
   - domain, guest-agent: the info is based on both the domain spec and the Guest Agent report

## Guest Agent info available through the API

The data shown in the VirtualMachineInstance status are a subset of the information available.
The rest of the data is available via the REST API exposed in the Kubernetes `kube-api` server.

There are three new subresources added to the VirtualMachineInstance object:

    - guestosinfo
    - userlist
    - filesystemlist


The whole GA data is returned via `guestosinfo` subresource available behind the API endpoint.

    /apis/subresources.kubevirt.io/v1alpha3/namespaces/{namespace}/virtualmachineinstances/{name}/guestosinfo


GuestOSInfo sample data:

    {
        "fsInfo": {
            "disks": [
                {
                    "diskName": "vda1",
                    "fileSystemType": "ext4",
                    "mountPoint": "/",
                    "totalBytes": 0,
                    "usedBytes": 0
                }
            ]
        },
        "guestAgentVersion": "2.11.2",
        "hostname": "testvmi6m5krnhdlggc9mxfsrnhlxqckgv5kqrwcwpgr5mdpv76grrk",
        "metadata": {
            "creationTimestamp": null
        },
        "os": {
            "id": "fedora",
            "kernelRelease": "4.18.16-300.fc29.x86_64",
            "kernelVersion": "#1 SMP Sat Oct 20 23:24:08 UTC 2018",
            "machine": "x86_64",
            "name": "Fedora",
            "prettyName": "Fedora 29 (Cloud Edition)",
            "version": "29 (Cloud Edition)",
            "versionId": "29"
        },
        "timezone": "UTC, 0"
    }

Items FSInfo and UserList are capped to the max capacity of 10 items, as a precaution for VMs with thousands of users.

Full list of Filesystems is available through the subresource `filesystemlist` which is available as endpoint.


    /apis/subresources.kubevirt.io/v1alpha3/namespaces/{namespace}/virtualmachineinstances/{name}/filesystemlist

Filesystem sample data:

    {
        "items": [
            {
                "diskName": "vda1",
                "fileSystemType": "ext4",
                "mountPoint": "/",
                "totalBytes": 3927900160,
                "usedBytes": 1029201920
            }
        ],
        "metadata": {}
    }

Full list of the Users is available through the subresource `userlist` which is available as endpoint.

    /apis/subresources.kubevirt.io/v1alpha3/namespaces/{namespace}/virtualmachineinstances/{name}/userlist



Userlist sample data:

    {
        "items": [
            {
                "loginTime": 1580467675.876078,
                "userName": "fedora"
            }
        ],
        "metadata": {}
    }

User LoginTime is in fractional seconds since epoch time. It is left for the consumer to convert to the desired format.
