# KubeVirt User-Guide

[![Build Status](https://travis-ci.org/kubevirt/kubevirt.github.io.svg?branch=master)](https://travis-ci.org/kubevirt/kubevirt.github.io)

## Contributing contents

We more than welcome contributions to KubeVirt documentation. Please reach out if you happen to have an idea or find an issue with our contents!

### Get started

- Create fork of GitHub user-guide repo

- Clone repository, check out source branch and prepare the Jekyll site
  ```console
  git clone -b master https://github.com/mygithubname/user-guide.git && cd user-guide
  ```

- Set up your git repo remotes like the following:
```
$ git remote -v
origin	git@github.com:mygithubname/user-guide.git (fetch)
origin	git@github.com:mygithubname/user-guide.git (push)
upstream	git@github.com:kubevirt/user-guide.git (fetch)
upstream	git@github.com:kubevirt/user-guide.git (push)
```

<<<<<<< HEAD
-   Start contributing: [Appendix/Contributing](appendix/contributing.md)
=======
- We use [mkdocs](https://www.mkdocs.org/) markdown engine with [mkdocs-awesome-pages](https://github.com/lukasgeiter/mkdocs-awesome-pages-plugin/) plugin
  - mkdocs config file
  - Each subdirectory of `./docs` contains a `.pages` file.  We use this to force the ordering of pages.  Alphabetical ordering is not ideal for technical documentation.
>>>>>>> 9bcee5e... Initial commit for migration to mkdocs

- Markdown lives under `./docs`.  Do your work here.

- When finished check your work by running:
 - `make check_spelling`
 - `make check_links`
 - `make run`

- Web browse to http://0.0.0.0:8000 and validate page rendering

- Commit your code
 - We do commit with signature verification so please do:
 `git commit -s -m "The commit message" file1 file 2 ...`

- Create GitHub pull request to master branch

#### Make Help
```console

Makefile for user-guide mkdocs application

Usage:
  make <target>

Env Variables:
  CONTAINER_ENGINE	Set container engine, [*podman*, docker]
  BUILD_ENGINE		Set build engine, [*podman*, buildah, docker]
  GIT_REPO_DIR		Set path to git repos, [*~/git*, /path/to/git/repos]
  SELINUX_ENABLED	Enable SELinux on containers, [*False*, True]

Targets:
  help                	 Show help
  check_links         	 Check external and internal links
  check_spelling      	 Check spelling on site content
  build_image_userguide	 Build image: userguide
  build_image_yaspeller	 Build image: yaspeller
  build               	 Build site. This target should only be used by Prow jobs.
  run                 	 Run site.  App available @ http://0.0.0.0:8000
  status              	 Container status
  stop                	 Stop site
  stop_yaspeller      	 Stop yaspeller image
```

#### Environment Variables
* CONTAINER_ENGINE: Some of us use docker. Some of use use podman.

* Build_ENGINE: Some of use docker. Some of us user podman or buildah.

* GIT_REPO_DIR: Default path for KubeVirt git repos is `~/git/*`.  Use this var if you store repos in a dir like `/opt/git/kubevirt`.

* SELINUX_ENABLED: Some of us run SELinux enabled. Set to to `True` to enable container mount labelling.

* DEBUG: This is normally hidden. Set to `True` to echo target commands to terminal.

#### Targets:

* check_links: HTMLProofer is used to check any links to external websites as we as any cross-page links

* check_spelling: yaspeller is used to check spelling.  If you see a failure here please feel free to make an update to  

* build_image_userguide: Build image packed with python and mkdocs app.  ./docs will be mounted.  ./site will be mounted as tmpfs...changes here are lost.

* status: Basically `${BUILD_ENGINE} ps` easy way to see what's running.

* stop: Stop container and app

* stop_yaspeller: Sometimes yaspeller goes bonkers.  Stop it here.

## Getting help

- File a bug: <https://github.com/kubevirt/user-guide/issues>

- Mailing list: <https://groups.google.com/forum/#!forum/kubevirt-dev>

- Slack: <https://kubernetes.slack.com/messages/virtualization>

# Developer

- Start contributing: [Appendix/Contributing](appendix/contributing.md)

## Privacy

- Check our privacy policy at: <https://kubevirt.io/privacy/>

- We do use <https://netlify.com> Open Source Plan for rendering Pull Requests to the documentation repository
