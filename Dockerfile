FROM alpine:3.5 AS build

# Install system utils & Gogs runtime dependencies
ADD https://github.com/tianon/gosu/releases/download/1.9/gosu-amd64 /usr/sbin/gosu
RUN chmod +x /usr/sbin/gosu \
  && echo http://dl-2.alpinelinux.org/alpine/edge/community/ >> /etc/apk/repositories \
  && apk --no-cache --no-progress add \
    bash \
    ca-certificates \
    curl \
    git \
    linux-pam \
    openssh \
    s6 \
    shadow \
    socat \
    tzdata

ENV GOGS_CUSTOM /data/gogs

# Configure LibC Name Service
COPY gogs/docker/nsswitch.conf /etc/nsswitch.conf
COPY gogs/docker /app/gogs/docker
COPY gogs/templates /app/gogs/templates
COPY gogs/public /app/gogs/public

WORKDIR /app/gogs/build
COPY gogs/ .

RUN    ./docker/build-go.sh \
    && ./docker/build.sh

FROM alpine:3.5
ADD https://github.com/tianon/gosu/releases/download/1.9/gosu-amd64 /usr/sbin/gosu
RUN apk --no-cache --no-progress add \
  bash \
  ca-certificates \
  git \
  openssh \
  s6 \
  shadow \
  && chmod +x /usr/sbin/gosu \
  && addgroup -S git \
  && adduser -G git -H -D -g 'Gogs Git User' git -h /data/git -s /bin/bash \
  && usermod -p '*' git \
  && passwd -u git \
  && echo "export GOGS_CUSTOM=${GOGS_CUSTOM}" >> /etc/profile

COPY --from=build /app/gogs/build/gogs /app/gogs/
COPY gogs/docker/nsswitch.conf /etc/nsswitch.conf
COPY gogs/docker /app/gogs/docker
COPY gogs/templates /app/gogs/templates
COPY gogs/public /app/gogs/public
# Configure Docker Container
VOLUME ["/data"]
EXPOSE 22 3000
ENTRYPOINT ["/app/gogs/docker/start.sh"]
CMD ["/bin/s6-svscan", "/app/gogs/docker/s6/"]
