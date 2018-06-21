# Virtual Machines

The `VirtualMachineInstance` type conceptionally has two parts:

* Information for making scheduling decisions
* Information about the virtual machine ABI

Every `VirtualMachineInstance` object represents a single running virtual machine instance.

[filename](https://raw.githubusercontent.com/kubevirt/kubevirt/master/cluster/examples/vm-alpine-multipvc.yaml ':include :type=code')
