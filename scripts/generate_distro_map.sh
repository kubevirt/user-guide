#!/bin/bash
# Description: This script generates a distro_map.yml with mentions to each release to build

releases() {
curl  "https://api.github.com/repos/kubevirt/kubevirt/tags" 2>&1|grep "name"|grep "v[0-9]*\.[0-9]*\.0\""|awk -F ":" '{print $2}'|tr -d '",v'|cut -d "." -f 1-2|grep -v 0.16|grep -v 0.15|grep -v 0.14
}

gen_distromap() {
  {
  # Pregenerate local branches for ascii_binder to work
  git fetch --all
  for REL in $(releases);
  do
    git branch release-$REL --track origin/release-$REL
  done

  cat << EOF > _distro_map.yml
---
kubevirt-community:
  name: KubeVirt
  author: KubeVirt Documentation Team
  site: community
  site_name: Documentation
  site_url: https://kubevirt.io/docs
  branches:
    master:
      name: Latest
      dir: latest
EOF

  # Prefill distro_map with releases
  for REL in $(releases);
  do
    echo "    release-$REL:" >> _distro_map.yml
    echo "      name: \"$REL\"" >> _distro_map.yml
    echo "      dir: \"$REL\"" >> _distro_map.yml
  done
  }
}

gen_distromap
