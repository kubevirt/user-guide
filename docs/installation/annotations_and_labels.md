KubeVirt specific annotations and labels
========================================

KubeVirt builds on and exposes a number of labels and annotations that
either are used for internal implementation needs or expose useful
information to API users. This page documents the labels and annotations
that may be useful for regular API consumers. This page intentionally
does *not* list labels and annotations that are merely part of internal
implementation.

**Note:** Annotations and labels that are not specific to KubeVirt are
also documented
[here](https://kubernetes.io/docs/reference/kubernetes-api/labels-annotations-taints/).

kubevirt.io
-----------

Example: `kubevirt.io=virt-launcher`

Used on: Pod

This label marks resources that belong to KubeVirt. An optional value
may indicate which specific KubeVirt component a resource belongs to.
This label may be used to list all resources that belong to KubeVirt,
for example, to uninstall it from a cluster.

kubevirt.io/schedulable
-----------------------

Example: `kubevirt.io/schedulable=true`

Used on: Node

This label declares whether a particular node is available for
scheduling virtual machine instances on it.

kubevirt.io/heartbeat
---------------------

Example: `kubevirt.io/heartbeat=2018-07-03T20:07:25Z`

Used on: Node

This annotation is regularly updated by virt-handler to help determine
if a particular node is alive and hence should be available for new
virtual machine instance scheduling.
