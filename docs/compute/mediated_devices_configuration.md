# Mediated devices and virtual GPUs
## Configuring mediated devices and virtual GPUs

KubeVirt aims to facilitate the configuration of mediated devices on large clusters.
Administrators can use the `mediatedDevicesConfiguration` API in the KubeVirt CR to
create or remove mediated devices in a declarative way, by providing a list of the desired mediated device types that they expect to be configured in the cluster.

You can also include the `nodeMediatedDeviceTypes` option to provide a more specific configuration that targets a specific node or a group of nodes directly with a node selector.
The `nodeMediatedDeviceTypes` option must be used in combination with `mediatedDevicesTypes`
in order to override the global configuration set in the `mediatedDevicesTypes` section.

KubeVirt will use the provided configuration to automatically create the relevant mdev/vGPU devices on nodes that can support it.

Currently, a single mdev type per card will be configured.
The maximum amount of instances of the selected mdev type will be configured per card.

> Note: Some vendors, such as NVIDIA, require a driver to be installed on the nodes to provide mediated devices, including vGPUs.

Example snippet of a KubeVirt CR configuration that includes both `nodeMediatedDeviceTypes` and `mediatedDevicesTypes`:
```yaml
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
### Example: Large cluster with multiple cards on each node

On nodes with multiple cards that can support similar vGPU types, the relevant desired types will be created in a round-robin manner.

For example, considering the following KubeVirt CR configuration:

```yaml
spec:
  configuration:
    mediatedDevicesConfiguration:
      mediatedDevicesTypes:
      - nvidia-222
      - nvidia-228
      - nvidia-105
      - nvidia-108
```

This cluster has nodes with two different PCIe cards:

1. Nodes with 3 Tesla T4 cards, where each card can support multiple devices types:
    * nvidia-222
    * nvidia-223
    * nvidia-228
    * ...

2. Nodes with 2 Tesla V100 cards, where each card can support multiple device types:
    * nvidia-105
    * nvidia-108
    * nvidia-217
    * nvidia-299
    * ...

KubeVirt will then create the following devices:

1. Nodes with 3 Tesla T4 cards will be configured with:
    * 16 vGPUs of type nvidia-222 on card 1
    * 2 vGPUs of type nvidia-228 on card 2
    * 16 vGPUs of type nvidia-222 on card 3
2. Nodes with 2 Tesla V100 cards will be configured with:
    * 16 vGPUs of type nvidia-105 on card 1
    * 2 vGPUs of type nvidia-108 on card 2


### Example: Single card on a node, multiple desired vGPU types are supported

When nodes only have a single card, the first supported type from the list will be configured.

For example, consider the following list of desired types, where nvidia-223 and nvidia-224 are supported:

```yaml
spec:
  configuration:
    mediatedDevicesConfiguration:
      mediatedDevicesTypes:
      - nvidia-223
      - nvidia-224
```
In this case, nvidia-223 will be configured on the node because it is the first supported type in the list.

## Overriding configuration on a specifc node

To override the global configuration set by `mediatedDevicesTypes`, include the `nodeMediatedDeviceTypes` option, specifying the node selector and the `mediatedDevicesTypes` that you want to override for that node.

### Example: Overriding the configuration for a specific node in a large cluster with multiple cards on each node

In this example, the KubeVirt CR includes the `nodeMediatedDeviceTypes` option to override the global configuration specifically for node 2, which will only use the nvidia-234 type.

```yaml
spec:
  configuration:
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

The cluster has two nodes that both have 3 Tesla T4 cards.

* Each card can support a long list of types, including:
    * nvidia-222
    * nvidia-223
    * nvidia-224
    * nvidia-230
    * ...

KubeVirt will then create the following devices:

1. Node 1
    * type nvidia-230 on card 1
    * type nvidia-223 on card 2
2. Node 2
    * type nvidia-234 on card 1 and card 2

Node 1 has been configured in a round-robin manner based on the global configuration but node 2 only uses the nvidia-234 that was specified for it.

## Updating and Removing vGPU types

Changes made to the `mediatedDevicesTypes` section of the KubeVirt CR will trigger a re-evaluation of the configured mdevs/vGPU types on the cluster nodes.

Any change to the node labels that match the `nodeMediatedDeviceTypes` nodeSelector in the KubeVirt CR will trigger a similar re-evaluation.

Consequently, mediated devices will be reconfigured or entirely removed based on the updated configuration.

## Assigning vGPU/MDEV to a Virtual Machine
See the [Host Devices Assignment](../compute/host-devices.md) to learn how to consume the newly created mediated devices/vGPUs.
