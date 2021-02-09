# COLORS
RED    := $(shell tput -Txterm setaf 1)
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
VIOLET := $(shell tput -Txterm setaf 5)
AQUA   := $(shell tput -Txterm setaf 6)
WHITE  := $(shell tput -Txterm setaf 7)
RESET  := $(shell tput -Txterm sgr0)


TARGET_MAX_CHAR_NUM=20


## Show help
help:
	@echo ''
	@echo 'Makefile for user-guide mkdocs application'
	@echo ''
	@echo 'Usage:'
	@echo '  ${YELLOW}make${RESET} ${GREEN}<target>${RESET}'
	@echo ''
	@echo 'Env Variables:'
	@printf "  ${YELLOW}CONTAINER_ENGINE${RESET}\tSet container engine, [*podman*, docker]\n"
	@printf "  ${YELLOW}BUILD_ENGINE${RESET}\t\tSet build engine, [*podman*, buildah, docker]\n"
	@printf "  ${YELLOW}GIT_REPO_DIR${RESET}\t\tSet path to git repos, [*~/git*, /path/to/git/repos]\n"
	@printf "  ${YELLOW}SELINUX_ENABLED${RESET}\tEnable SELinux on containers, [*False*, True]\n"
	@echo ''
	@echo 'Targets:'
	@awk '/^[a-zA-Z\-_0-9]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")-1); \
			helpMessage = substr(lastLine, RSTART + 2, RLENGTH); \
			printf "  ${YELLOW}%-$(TARGET_MAX_CHAR_NUM)s${RESET}\t${GREEN}%s${RESET}\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)


envvar:
ifndef BUILD_ENGINE
	@$(eval export BUILD_ENGINE=podman build . -t)
else
ifeq ($(shell test "${BUILD_ENGINE}" == "podman" || test "${BUILD_ENGINE}" == "podman build . -t" && printf true), true)
	@$(eval export BUILD_ENGINE=podman build . -t)
else ifeq ($(shell test "${BUILD_ENGINE}" == "buildah" || test "${BUILD_ENGINE}" == "buildah build-using-dockerfile -t" && printf "true"), true)
	@$(eval export BUILD_ENGINE=buildah build-using-dockerfile -t)
else ifeq ($(shell test "${BUILD_ENGINE}" == "docker" || test "${BUILD_ENGINE}" == "docker build . -t" && printf "true"), true)
	@$(eval export BUILD_ENGINE=docker build . -t)
else
	@echo ${BUILD_ENGINE}
	@echo "Invalid value for BUILD_ENGINE ... exiting"
endif
endif

ifndef CONTAINER_ENGINE
	@$(eval CONTAINER_ENGINE=podman)
else
ifeq ($(shell test "$(CONTAINER_ENGINE)" = "podman" && printf true), true)
	@$(eval export CONTAINER_ENGINE=podman)
else ifeq ($(shell test "$(CONTAINER_ENGINE)" = "docker" && printf "true"), true)
	@$(eval export CONTAINER_ENGINE=docker)
else
	@echo ${CONTAINER_ENGINE}
	@echo "Invalid value for CONTAINER_ENGINE ... exiting"
endif
endif

ifndef DEBUG
	@$(eval export DEBUG=@)
else
ifeq ($(shell test "$(DEBUG)" = True  -o  \
	                 "$(DEBUG)" = true && printf "true"), true)
	@$(eval export DEBUG=)
else
	@$(eval export DEBUG=@)
endif
endif

ifndef GIT_REPO_DIR
	@$(eval GIT_REPO_DIR=~/git)
endif

ifdef SELINUX_ENABLED
ifeq ($(shell test "$(SELINUX_ENABLED)" = True  -o  \
                   "$(SELINUX_ENABLED)" = true && printf "true"), true)
		@$(eval export SELINUX_ENABLED=,Z)
endif
endif
	@echo


## Check external and internal links
check_links: | envvar stop
	@echo "${GREEN}Makefile: Check external and internal links${RESET}"
	${DEBUG}export IFS=$$'\n'; \
	${CONTAINER_ENGINE} run -it --rm --name userguide -v ${PWD}:/srv:ro${SELINUX_ENABLED} --mount type=tmpfs,destination=/srv/site userguide /bin/bash -c 'cd /srv; bundle install --quiet; rake -- -u'
	@echo


## Check spelling on content
check_spelling: | envvar stop
	@echo "${GREEN}Makefile: Check spelling on site content${RESET}"
	${DEBUG}if [ ! -e "./yaspeller.json" ]; then \
		echo "Dictionary file: https://raw.githubusercontent.com/kubevirt/project-infra/master/images/yaspeller/.yaspeller.json"; \
	  if [ "`curl https://raw.githubusercontent.com/kubevirt/project-infra/master/images/yaspeller/.yaspeller.json -o yaspeller.json -w '%{http_code}\n' -s`" != "200" ]; then \
			echo "Unable to curl yaspeller dictionary file"; \
			RETVAL=1; \
		fi; \
		REMOTE=1; \
	else \
		echo "Using local dictionary file"; \
	  echo "Dictionary file: yaspeller.json"; \
		echo "Be sure to add changes to upstream: kubevirt/project-infra/master/images/yaspeller/.yaspeller.json"; \
	fi; \
	export IFS=$$'\n'; \
	if `cat ./yaspeller.json 2>&1 | jq > /dev/null 2>&1`; then \
		for i in `${CONTAINER_ENGINE} run -it --rm --name yaspeller -v ${PWD}:/srv:ro${SELINUX_ENABLED} -v /dev/null:/srv/Gemfile.lock -v ./yaspeller.json:/srv/yaspeller.json:ro${SELINUX_ENABLED} yaspeller /bin/bash -c 'echo; yaspeller -c /srv/yaspeller.json --only-errors --ignore-tags iframe,img,code,kbd,object,samp,script,style,var /srv'`; do \
			if [[ "$${i}" =~ "✗" ]]; then \
				RETVAL=1; \
			fi; \
		echo "$${i}" | sed -e 's/\/srv\//\.\//g'; \
		done; \
	else \
		echo "yaspeller dictionary file does not exist or is invalid json"; \
		RETVAL=1; \
	fi; \
	if [ "$${REMOTE}" ]; then \
		rm -rf yaspeller.json > /dev/null 2>&1; \
	fi; \
	if [ "$${RETVAL}" ]; then exit 1; else echo "Complete!"; fi


## Build image: userguide
build_image_userguide: stop
	${DEBUG}$(eval export DIR=${GIT_REPO_DIR}/project-infra/images/kubevirt-userguide)
	${DEBUG}$(eval export TAG=localhost/userguide:latest)
	${DEBUG}$(MAKE) build_image
	@echo


## Build image: yaspeller
build_image_yaspeller: stop_yaspeller
	${DEBUG}$(eval export DIR=${GIT_REPO_DIR}/project-infra/images/yaspeller)
	${DEBUG}$(eval export TAG=localhost/yaspeller:latest)
	${DEBUG}$(MAKE) build_image
	@echo


build_image: envvar
	@echo "${GREEN}Makefile: Building image: ${TAG}${RESET}"
ifeq ($(DIR),)
	@echo "This is a sourced target!"
	@echo "Do not run this target directly... exitting!"
	exit 1
endif
	cd ${DIR} && \
	(${CONTAINER_ENGINE} rmi ${TAG} || echo -n) && \
	${BUILD_ENGINE} ${TAG}


## Build site. This target should only be used by Prow jobs.
build: envvar
	@echo "${GREEN}Makefile: Build mkdocs site.  This should only be used by a Prow job.${RESET}"
	if [ `which python3.7` ]; then \
		python3.7 -m venv /tmp/venv; \
		. /tmp/venv/bin/activate; \
		pip3 install mkdocs mkdocs-awesome-pages-plugin mkdocs-htmlproofer-plugin; \
		echo '*** BEGIN mkdocs.yml ***'; \
		cat mkdocs.yml; \
		echo '*** END mkdocs.yml ***'; \
		mkdocs build -f mkdocs.yml -d site; \
	else \
		echo 'python3.7 not found.  exiting...'; \
		exit 2; \
	fi; echo

## Run site.  App available @ http://0.0.0.0:8000
run: | envvar stop
	@echo "${GREEN}Makefile: Run site${RESET}"
	${CONTAINER_ENGINE} run -d --name userguide --net=host -v ./:/srv:ro${SELINUX_ENABLED} --mount type=tmpfs,destination=/srv/site localhost/userguide:latest /bin/bash -c "mkdocs build -f /srv/mkdocs.yml && mkdocs serve -f /srv/mkdocs.yml -a 0.0.0.0:8000"
	@echo


## Container status
status: | envvar
	@echo "${GREEN}Makefile: Check image status${RESET}"
	${CONTAINER_ENGINE} ps
	@echo


## Stop site
stop: | envvar
	@echo "${GREEN}Makefile: Stop site${RESET}"
	${CONTAINER_ENGINE} rm -f userguide 2> /dev/null; echo
	@echo -n


## Stop yaspeller image
stop_yaspeller: | envvar
	@echo "${GREEN}Makefile: Stop yaspeller image${RESET}"
	${CONTAINER_ENGINE} rm -f yaspeller 2> /dev/null; echo
	@echo -n
