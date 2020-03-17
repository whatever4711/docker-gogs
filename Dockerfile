## first image to build gogs
FROM golang:alpine as build

ENV GOOS=linux
ENV CGO_ENABLED=1

ADD /gogs /go/gogs/build

RUN apk add -U --no-cache \
    linux-pam-dev \
    build-base \
    git
RUN mkdir -p /go/src/github.com/gogs && \
    ln -s /go/gogs/build/ /go/src/github.com/gogs/gogs
RUN cd /go/src/github.com/gogs/gogs && \
    sed -i -e 's#pkg/bindata/bindata.go: $(DATA_FILES)#pkg/bindata/bindata.go:#g' \
        -e 's#-pkg=bindata conf/...#-pkg=bindata $(DATA_FILES)#g' Makefile && \
    go get -d -v
RUN cd /go/src/github.com/gogs/gogs && \
    make build TAGS="sqlite cert pam"

#  export GOARCH=$(echo $(uname -m) | sed -e "s|arm.*|arm|g" -e "s|aarch64|arm64|g" -e "s|i386|386|g" -e "s|x86_64|amd64|g") && \

# third image to be deployed on dockerhub
FROM alpine
##ARG QEMU=x86_64
##COPY --from=qemu /usr/bin/qemu-${QEMU}-static /usr/bin/qemu-${QEMU}-static
##COPY --from=qemu /usr/sbin/gosu /usr/sbin/gosu
##ARG ARCH=amd64
##ARG BUILD_DATE
##ARG VCS_REF
##ARG VCS_URL
##ARG VERSION
#
RUN apk --no-cache --no-progress add \
  bash \
  ca-certificates \
  git \
  openssh \
  s6 \
  shadow \
  tini \
  curl \
  && addgroup -S git \
  && adduser -G git -H -D -g 'Gogs Git User' git -h /data/git -s /bin/bash \
  && usermod -p '*' git \
  && passwd -u git \
  && export GOSUARCH=$(echo $(uname -m) | sed -e "s|arm.*|arm|g" -e "s|aarch64|arm64|g" -e "s|x86_64|amd64|g" ) \
  && curl -sSL -o /usr/sbin/gosu https://github.com/tianon/gosu/releases/download/1.10/gosu-${GOSUARCH} \
  && chmod +x /usr/sbin/gosu
#  && echo "export GOGS_CUSTOM=${GOGS_CUSTOM}" >> /etc/profile
## SSH login fix. Otherwise user is kicked off after login
##RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
RUN sed -e 's@UsePrivilegeSeparation yes@UsePrivilegeSeparation no@' \
        -e 's@#RSAAuthentication yes@RSAAuthentication yes@' \
        -e 's@#PubkeyAuthentication yes@PubkeyAuthentication yes@' -i /etc/ssh/sshd_config && \
    echo "export VISIBLE=now" >> /etc/profile && \
    echo "PermitUserEnvironment yes" >> /etc/ssh/sshd_config
#
COPY --from=build /go/gogs/build/gogs /app/gogs/gogs
COPY gogs/docker/nsswitch.conf /etc/nsswitch.conf
COPY gogs/docker/s6 /app/gogs/docker/s6
COPY gogs/docker/sshd_config gogs/docker/start.sh /app/gogs/docker/
COPY gogs/templates /app/gogs/templates
COPY gogs/public /app/gogs/public
# Configure Docker Container
VOLUME ["/data"]
EXPOSE 22 3000
ENTRYPOINT ["tini", "--", "/app/gogs/docker/start.sh"]
CMD ["/bin/s6-svscan", "/app/gogs/docker/s6/"]

LABEL de.whatever4711.gogs.version=$VERSION \
    de.whatever4711.gogs.name="Gogs" \
    de.whatever4711.gogs.docker.cmd="docker run -d -p 3000:3000 -p 2222:22 whatever4711/gogs" \
    de.whatever4711.gogs.vendor="Marcel Grossmann" \
    de.whatever4711.gogs.architecture=$ARCH \
    de.whatever4711.gogs.vcs-ref=$VCS_REF \
    de.whatever4711.gogs.vcs-url=$VCS_URL \
    de.whatever4711.gogs.build-date=$BUILD_DATE
