# Mediated devices and virtual GPUs

KubeVirt aims to facilitate the configuration of mediated devices on large clusters.
The new `mediatedDevicesConfiguration` API in KubeVirt CR allows administrators to
create or remove mediated devices in a declarative way, by providing a list of the desired mediated devices types  that they expect to be configured in the cluster.

It would also be possible to provide a more specific configuration that targets a specific node or a group of nodes directly.
This can be achieved by using the `nodeMediatedDeviceTypes`, however, it must be used in a combination with `mediatedDevicesTypes`, to override the global
configuration set in `mediatedDevicesTypes` section. Therefore, using `nodeMediatedDeviceTypes` without the `mediatedDevicesTypes` section is not supported.


KubeVirt will use the provided configuration to automatically create the relevant mdev/vGPU devices on nodes that can support it.

Currently, a single mdev type per card will be configured.
The maximum amount of instances of the selected mdev type will be configured per card.

> Note: Some vendors, such as NVIDIA, require a driver to be installed on the nodes to provide mediated devices, including vGPUs.

Here's an example of a configuration that can be provided to KubeVirt CR:
```
spec:  
  configuration:  
     mediatedDevicesConfiguration:  
       mediatedDevicesTypes:  
       - nvidia-222  
       - nvidia-228  
       nodeMediatedDeviceTypes:  
       - nodeSelector:  
           kubernetes.io/hostname: nodeName  
         mediatedDevicesTypes:  
         - nvidia-234
```

## Configuration scenarios
### Large cluster with multiple cards on each node

On nodes with multiple cards that can support similar vGPU types, the relevant desired types will be created in a round-robin manner.  

#### For example, considering the following configuration:  
```
mediatedDevicesConfiguration:
  mediatedDevicesTypes:
  - nvidia-222
  - nvidia-228
  - nvidia-105
  - nvidia-108
```
* Nodes with 2 Tesla T4 cards
  * Each card can support multiple types:
    * nvidia-222
    * nvidia-223
    * nvidia-228
    * ...
* Nodes with 2 Tesla V100 cards
  * Each card can support multiple types:
    * nvidia-105
    * ...
    * nvidia-108
    * nvidia-217
    * nvidia-299
    * ...

KubeVirt will create the following devices:

* Nodes with 3 Tesla T4 cards will be configured with
  * 16 vGPUs of type nvidia-222 on card 1
  * 2 vGPUs of type nvidia-228 on card 2
  * 16 vGPUs of type nvidia-222 on card 3
* Nodes with 2 Tesla V100 cards will be configured with
  * 16 vGPUs of type nvidia-105 on card 1
  * 2 vGPUs of type nvidia-108 on card 2


### Single card on a node, multiple desired vGPU types are supported

The first supported type from the list will be configured  
##### For example, consider the following list of desired types, where nvidia-223 and nvidia-224 are supported:
```
mediatedDevicesConfiguration:
  mediatedDevicesTypes:  
  - nvidia-22  
  - nvidia-223  
  - nvidia-224
```
In this case, nvidia-223 will be configured on the node.

### Overriding configuration on a specifc node

`nodeMediatedDeviceTypes` needs to be used along with `mediatedDevicesTypes`, to override the global config brought in by, `mediatedDevicesTypes`.

#### For example, considering the following configuration:  
```
mediatedDevicesConfiguration:
  mediatedDevicesTypes:  
  - nvidia-230
  - nvidia-223  
  - nvidia-224
  nodeMediatedDeviceTypes:  
  - nodeSelector:  
      kubernetes.io/hostname: node2  
    mediatedDevicesTypes:  
    - nvidia-234
```
* Two nodes has 2 Tesla T4 cards
  * Each card can support a long list of types:
    * nvidia-222
    * nvidia-223
    * nvidia-224
    * nvidia-230
    * ...

KubeVirt will create the following devices:
* Node 1
  * type nvidia-230 on card 1
  * type nvidia-223 on card 2
* Node 2
  * type nvidia-234 on card 1 and card 2


### Updating and Removing vGPU types

Changes made to the mediatedDevicesTypes section of the KubeVirt CR will trigger a re-evaluation of the configured mdevs/vGPU types on the cluster nodes.

Any change to the node labels that match the nodeMediatedDeviceTypes nodeSelector in the KubeVirt CR will trigger a similar re-evaluation.

Consequently, mediated devices will be reconfigured or entirely removed based on the updated configuration.

## Assigning vGPU/MDEV to a Virtual Machine
See the [Host Devices Assignment](<../virtual_machines/host-devices.md>) to learn how to consume the newly created mediated devices/vGPUs
