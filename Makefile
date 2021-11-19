.PHONY: help envvar \
				check_links check_spelling \
				build build_img \
				status run stop

# COLORS
RED    := $(shell tput -Txterm setaf 1)
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
VIOLET := $(shell tput -Txterm setaf 5)
AQUA   := $(shell tput -Txterm setaf 6)
WHITE  := $(shell tput -Txterm setaf 7)
RESET  := $(shell tput -Txterm sgr0)


TARGET_MAX_CHAR_NUM=20

PYTHON ?= python3.7
PIP ?= pip3

LOCAL_SERVER_PORT ?= 8000


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
	@printf "  ${YELLOW}SELINUX_ENABLED${RESET}\tEnable SELinux on containers, [*False*, True]\n"
	@printf "  ${YELLOW}LOCAL_SERVER_PORT${RESET}\tPort on which the local mkdocs server will run, [*8000*]\n"
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

ifdef SELINUX_ENABLED
ifeq ($(shell test "$(SELINUX_ENABLED)" = True  -o  \
									 "$(SELINUX_ENABLED)" = true && printf "true"), true)
		@$(eval export SELINUX_ENABLED=,Z)
else
		@$(eval export SELINUX_ENABLED='')
endif
endif
	@echo

ifndef IMGTAG
	@$(eval export IMGTAG=localhost/kubevirt-user-guide)
else
ifeq ($(shell test $IMGTAG > /dev/null 2>&1 && printf "true"), true)
	@echo WARN: Using IMGTAG=$$IMGTAG
	@echo
else
	@$(eval export IMGTAG=localhost/kubevirt-user-guide)
endif
endif


## Build site. This target should only be used by Netlify and Prow
build: envvar
	@echo "${GREEN}Makefile: Build mkdocs site${RESET}"
	which $(PYTHON)
	$(PYTHON) -m venv /tmp/venv
	. /tmp/venv/bin/activate
	$(PIP) install mkdocs mkdocs-awesome-pages-plugin mkdocs-htmlproofer-plugin
	@echo
	@echo '*** BEGIN cat mkdocs.yml ***'
	@cat mkdocs.yml
	@echo '*** END cat mkdocs.yml ***'
	mkdocs build -f mkdocs.yml -d site


## Build image localhost/kubevirt-user-guide
build_img: | envvar
	@echo "${GREEN}Makefile: Building Image ${RESET}"
	${DEBUG}if [ ! -e "./Dockerfile" ]; then \
	  IMAGE="`echo $${IMGTAG} | sed -e s#\'##g -e s#localhost\/## -e s#:latest##`";  \
		echo "Downloading Dockerfile file: https://raw.githubusercontent.com/kubevirt/project-infra/main/images/kubevirt-user-guide/Dockerfile"; \
	  if ! `curl -f -s https://raw.githubusercontent.com/kubevirt/project-infra/main/images/kubevirt-user-guide/Dockerfile -o ./Dockerfile`; then \
			echo "${RED}ERROR: Unable to curl Dockerfile... exiting!${RESET}"; \
			exit 2; \
		else \
			echo "${WHITE}Dockerfile file updated${RESET}"; \
			echo; \
			REMOTE=1; \
		fi; \
	else \
		IMAGE="`echo $${TAG} | sed -e s#\'##g -e s#localhost\/## -e s#:latest##`"; \
		echo "Using Dockerfile file: ./Dockerfile"; \
		echo "Be sure to add changes to upstream: kubevirt/project-infra/main/images/${IMGTAG}/Dockerfile"; \
		echo; \
	fi; \
	${CONTAINER_ENGINE} rmi ${IMGTAG} 2> /dev/null || echo -n; \
	${BUILD_ENGINE} ${IMGTAG}; \
	if [ "$${REMOTE}" ]; then rm -f Dockerfile > /dev/null 2>&1; fi


## Check external and internal links
check_links: | envvar stop
	@echo "${GREEN}Makefile: Check external and internal links${RESET}"
	${DEBUG}export IFS=$$'\n'; \
	${CONTAINER_ENGINE} run \
		-it \
		--rm \
		--name userguide \
		-v ${PWD}:/srv:ro${SELINUX_ENABLED} \
		-v /dev/null:/srv/Gemfile.lock \
		--mount type=tmpfs,destination=/srv/site \
		--workdir=/srv \
		${IMGTAG} \
		/bin/bash -c 'rake -- -u'
	@echo


## Check spelling on content
check_spelling: | envvar stop
	@echo "${GREEN}Makefile: Check spelling on site content${RESET}"
	${DEBUG}if [ ! -e "./yaspeller.json" ]; then \
		echo "${WHITE}Downloading Dictionary file: https://raw.githubusercontent.com/kubevirt/project-infra/main/images/yaspeller/.yaspeller.json${RESET}"; \
		if ! `curl -f -s https://raw.githubusercontent.com/kubevirt/project-infra/main/images/yaspeller/.yaspeller.json -o yaspeller.json`; then \
			echo "${RED}ERROR: Unable to curl yaspeller dictionary file... exiting!${RESET}"; \
			exit 2; \
		else \
			echo "${WHITE}Dictionary file updated${RESET}"; \
			echo; \
			REMOTE=1; \
		fi; \
	else \
		echo "YASPELLER file: ./yaspeller.json"; \
		echo "Be sure to add changes to upstream: kubevirt/project-infra/main/images/yaspeller/.yaspeller.json"; \
		echo; \
	fi; \
	if `jq -C  . yaspeller.json > /dev/null 2>&1`; then \
		${CONTAINER_ENGINE} run -it --rm --name userguide -v ${PWD}:/srv:ro${SELINUX_ENABLED} -v ${PWD}/yaspeller.json:/srv/yaspeller.json:ro${SELINUX_ENABLED} --workdir=/srv ${IMGTAG} /bin/bash -c 'yaspeller -c /srv/yaspeller.json --only-errors --ignore-tags iframe,img,code,kbd,object,samp,script,style,var /srv' | sed -e 's/\/srv/./g'; \
	else \
		echo "${RED}ERROR: yaspeller dictionary file does not exist or is invalid json ${RESET}"; \
		exit 1; \
	fi; \
	if [ "$${REMOTE}" ]; then rm -f yaspeller.json > /dev/null 2>&1; fi


## Run site.  App available @ http://0.0.0.0:8000
run: | envvar stop
	@echo "${GREEN}Makefile: Run site${RESET}"
	${CONTAINER_ENGINE} run \
		-d \
		--name userguide \
		-p ${LOCAL_SERVER_PORT}:8000 \
		-v ${PWD}:/srv:ro${SELINUX_ENABLED} \
		-v /dev/null:/srv/Gemfile.lock:rw${SELINUX_ENABLED} \
		--mount type=tmpfs,destination=/srv/site \
		${IMGTAG} \
		/bin/bash -c "mkdocs build -f /srv/mkdocs.yml && mkdocs serve -f /srv/mkdocs.yml -a 0.0.0.0:8000"
	@echo
	@echo "${AQUA}Makefile: Server now running at [http://localhost:$(LOCAL_SERVER_PORT)]${RESET}"
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
