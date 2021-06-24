#!/bin/bash -x
set -e

[[ -e kubevirt ]] || git clone https://github.com/kubevirt/kubevirt.git kubevirt
git -C kubevirt checkout main
git -C kubevirt fetch --tags

releases() {
  # I'm sure some one can do better here
  if [ $# -eq 1 ]; then
    git -C kubevirt tag | sort -rV | egrep -v "alpha|rc|cnv" | grep "$1"
  else
    git -C kubevirt tag | sort -rV | egrep -v "alpha|rc|cnv" | head -1
  fi
}

features_for() {
  git -C kubevirt show $1 | grep Date: | head -n1 | sed -e "s/Date:\s\+/Released on: /"
  git -C kubevirt show $1 | sed -n "/changes$/,/Contributors/ p" | sed -e '1d;2d;$d'
}

gen_changelog() {
  IFS=$'\n'
  sed -i -e "s/# Latest release notes//" ./docs/latest_release_notes.md
  REL_NOTES=$(for REL in `releases $1`; do
    echo -e "## $REL\n" ;
    features_for $REL
  done)
  printf '%s %s\n' "$REL_NOTES `cat docs/latest_release_notes.md`" > ./docs/latest_release_notes.md
  sed -i "1 i\# Latest release notes\n" ./docs/latest_release_notes.md
  sed -i 's/[ \t]*$//' docs/latest_release_notes.md
}

gen_changelog $1
