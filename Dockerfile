FROM pulumi/pulumi:3.129.0

ENV TINI_VERSION='0.18.0'
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    ca-certificates \
    gnupg \
    dirmngr \
    && dpkgArch="$(dpkg --print-architecture)" \
    && wget -O /usr/local/bin/tini "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-${dpkgArch}" \
    && wget -O /usr/local/bin/tini.asc "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-${dpkgArch}.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --batch --keyserver hkps://keyserver.ubuntu.com --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 \
    && gpg --batch --verify /usr/local/bin/tini.asc /usr/local/bin/tini \
    && gpgconf --kill all \
    && rm -rf "$GNUPGHOME" /usr/local/bin/tini.asc \
    && chmod +x /usr/local/bin/tini \
    && tini --version \
    && apt-get purge -y --auto-remove gnupg dirmngr \
    && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["tini", "--", "/usr/local/bin/pulumi-kubernetes-operator"]

# install operator binary
COPY pulumi-kubernetes-operator /usr/local/bin/pulumi-kubernetes-operator

RUN useradd -m pulumi-kubernetes-operator
RUN mkdir -p /home/pulumi-kubernetes-operator/.ssh \
    && touch /home/pulumi-kubernetes-operator/.ssh/known_hosts \
    && chmod 700 /home/pulumi-kubernetes-operator/.ssh \
    && chown -R pulumi-kubernetes-operator:pulumi-kubernetes-operator /home/pulumi-kubernetes-operator/.ssh

USER pulumi-kubernetes-operator

ENV XDG_CONFIG_HOME=/tmp/.config
ENV XDG_CACHE_HOME=/tmp/.cache
ENV XDG_CONFIG_CACHE=/tmp/.cache
ENV GOCACHE=/tmp/.cache/go-build
ENV GOPATH=/tmp/.cache/go