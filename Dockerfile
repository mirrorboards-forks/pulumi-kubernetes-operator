FROM pulumi/pulumi:3.129.0

# https://github.com/krallin/tini/issues/140
# https://github.com/docker-library/redmine/blob/73eaf95c886dcb2b75b1aeb65db5bdff6a0cad98/4.0/Dockerfile#L50-L60

# Detect architecture and install tini manually
RUN dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" && echo "Architecture: $dpkgArch"

RUN wget -O /usr/local/bin/tini "https://github.com/krallin/tini/releases/download/v$TINI_VERSION/tini-$dpkgArch" \
    && wget -O /usr/local/bin/tini.asc "https://github.com/krallin/tini/releases/download/v$TINI_VERSION/tini-$dpkgArch.asc"

RUN export GNUPGHOME="$(mktemp -d)" \
    && gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys 6380DC428747F6C393FEACA59A84159D7001A4E5 \
    && gpg --batch --verify /usr/local/bin/tini.asc /usr/local/bin/tini \
    && gpgconf --kill all \
    && rm -r "$GNUPGHOME" /usr/local/bin/tini.asc \
    && chmod +x /usr/local/bin/tini
    
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