# KubeVirt User-Guide

[![Netlify Status](https://api.netlify.com/api/v1/badges/2430a4f6-4a28-4e60-853d-f0cc395e13bb/deploy-status)](https://app.netlify.com/sites/kubevirt-user-guide/deploys)

## Contributing contents

We more than welcome contributions to KubeVirt documentation. Please reach out if you happen to have an idea or find an issue with our contents!

## Get started

### Fork this repository

### Make changes to your fork

You can find the markdown that powers the user guide in `./docs`, most commits are to that area.

We use [mkdocs](https://www.mkdocs.org/) markdown engine with [mkdocs-awesome-pages](https://github.com/lukasgeiter/mkdocs-awesome-pages-plugin/) plugin
  - mkdocs config file
  - Each subdirectory of `./docs` contains a `.pages` file.  We use this to force the ordering of pages.  Alphabetical ordering is not ideal for technical documentation.

#### Sign your commits

Signature verification on commits are required -- you may sign your commits by running:

```console
$ git commit -s -m "The commit message" file1 file 2 ...
```

If you need to sign all commits from a certain point (for example, `main`), you may run:

```console
git rebase --exec 'git commit --amend --no-edit -n -s' -i main
```

Signed commit messages generally take the following form:

```
<your commit message>

Signed-off-by: <your configured git identity>
```


### Test your changes locally:

```console
$ make check_spelling
$ make check_links
$ make build_img
$ make run
```

**NOTE** If you use `docker` you may need to set `CONTAINER_ENGINE` and `BUILD_ENGINE`:

```console
$ export CONTAINER_ENGINE=docker
$ export BUILD_ENGINE=docker
$ make run
```

<!-- markdown-link-check-disable -->
Open your web browser to http://0.0.0.0:8000 and validate page rendering
<!-- markdown-link-check-enable -->

### Create a pull request to `kubevirt/user-guide`

After you have vetted your changes, make a PR to `kubevirt/user-guide` so that others can review.

## Makefile Help

```console
Makefile for user-guide mkdocs application

Usage:
  make <target>

Env Variables:
  CONTAINER_ENGINE      Set container engine, [*podman*, docker]
  BUILD_ENGINE          Set build engine, [*podman*, buildah, docker]
  SELINUX_ENABLED       Enable SELinux on containers, [*False*, True]
  LOCAL_SERVER_PORT     Port on which the local mkdocs server will run, [*8000*]

Targets:
  help                   Show help
  check_links            Check external and internal links
  check_spelling         Check spelling on site content
  build_img  Build image: userguide
  build_image_yaspeller  Build image: yaspeller
  build                  Build site. This target should only be used by Prow jobs.
  run                    Run site.  App available @ http://0.0.0.0:8000
  status                 Container status
  stop                   Stop site
  stop_yaspeller         Stop yaspeller image
```

### Environment Variables

* `CONTAINER_ENGINE`: Some of us use `docker`. Some of us use `podman` (default: `podman`).

* `BUILD_ENGINE`: Some of us use `docker`. Some of us use `podman` or `buildah` (default: `podman`).

* `SELINUX_ENABLED`: Some of us run SELinux enabled. Set to `True` to enable container mount labelling.

* `PYTHON`: Change the `python` executable used (default: `python3.7`).

* `PIP`: Change the `pip` executable used (default: `pip3`).

* `LOCAL_SERVER_PORT`: Port on which the local `mkdocs` server will run, i.e. `http://localhost:<port>` (default: `8000`).

* `DEBUG`: This is normally hidden. Set to `True` to echo target commands to terminal.

### Targets:

* check_links: HTMLProofer is used to check any links to external websites as we as any cross-page links

* check_spelling: yaspeller is used to check spelling.  Feel free to update to the dictionary file as needed (`kubevirt/project-infra/images/yaspeller/.yaspeller.json`).

* build_img: mkdocs project does not provide a container image.  Use this target to build an image packed with python and mkdocs app.  ./docs will be mounted.  ./site will be mounted as tmpfs...changes here are lost.

* build_image_yaspeller: yaspeller project does not provide a container image.  User this target to Build an image packed with nodejs and yaspeller app.  ./docs will be mounted.  yaspeller will check content for spelling and other bad forms of English.

* status: Basically `${BUILD_ENGINE} ps` for an easy way to see what's running.

* stop: Stop container and app

* stop_yaspeller: Sometimes yaspeller goes bonkers.  Stop it here.

## Getting help

- File a bug: <https://github.com/kubevirt/user-guide/issues>

- Mailing list: <https://groups.google.com/forum/#!forum/kubevirt-dev>

- Slack: <https://kubernetes.slack.com/messages/virtualization>

## Developer

- Start contributing: <https://kubevirt.io/user-guide/appendix/contributing>

## Privacy

- Check our privacy policy at: <https://kubevirt.io/privacy/>

- We do use <https://netlify.com> Open Source Plan for rendering Pull Requests to the documentation repository
