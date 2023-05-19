# Hugepages support

For hugepages support you need at least Kubernetes version `1.9`.

## Enable feature-gate

To enable hugepages on Kubernetes, check the [official
documentation](https://kubernetes.io/docs/tasks/manage-hugepages/scheduling-hugepages/).

To enable hugepages on OKD, check the [official
documentation](https://docs.openshift.org/3.9/scaling_performance/managing_hugepages.html#huge-pages-prerequisites).

## Pre-allocate hugepages on a node

To pre-allocate hugepages on boot time, you will need to specify
hugepages under kernel boot parameters `hugepagesz=2M hugepages=64` and
restart your machine.

You can find more about hugepages under [official
documentation](https://www.kernel.org/doc/Documentation/vm/hugetlbpage.txt).
