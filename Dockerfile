# BASE
FROM registry.fedoraproject.org/fedora:43

ENV LC_ALL=en_US.UTF-8

# UPDATE BASE and land app frameworks and dependencies
RUN mkdir -p /src && cd /src && \
    curl https://raw.githubusercontent.com/kubevirt/user-guide/main/_config/src/Gemfile -o Gemfile && \
    dnf update -y && \
    dnf install -y langpacks-en glibc-all-langpacks @development-tools \
      redhat-rpm-config openssl-devel gcc-c++ tar jq bzip2 fontconfig \
      nodejs npm python3-pip ruby ruby-devel rubygems rubygems-devel \
      rubygem-bundler rubygem-json rubygem-nenv rubygem-rake && \
    alternatives --install /usr/bin/python python /usr/bin/python3 1 && \
    npm install -g markdownlint-cli@latest yaspeller@latest && \
    cd /src && bundle install && bundle update && cd && \
    pip install --upgrade pip && \
    pip install mkdocs mkdocs-material mkdocs-awesome-pages-plugin mkdocs-htmlproofer-plugin mkdocs-redirects mkdocs-static-i18n && \
    gem list && \
    rpm -e --nodeps libX11 libX11-common libXrender libXft && \
    dnf remove -y @development-tools gcc qt5-srpm-macros \
      xkeyboard-config qrencode-libs memstrack \
      openssl-devel ruby-devel rubygems-devel \
      nodejs-docs rubygem-rdoc glibc-all-langpacks vim-minimal tar \
      diffutils npm pigz bzip2 xz python3-pip jq -x git -x make && \
    dnf clean all && \
    rm -rf /root/{.bundle,.config,.npm,anaconda*,original-ks.cfg} /tmp/phantomjs /var/cache/dnf

EXPOSE 8000/tcp
