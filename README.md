[![CircleCI](https://circleci.com/gh/whatever4711/docker-gogs.svg?style=svg)](https://circleci.com/gh/whatever4711/docker-gogs)

[![](https://images.microbadger.com/badges/version/whatever4711/gogs.svg)](https://microbadger.com/images/whatever4711/gogs "Get your own version badge on microbadger.com")  [![](https://images.microbadger.com/badges/image/whatever4711/gogs.svg)](https://microbadger.com/images/whatever4711/gogs "Get your own image badge on microbadger.com")

# Gogs in a Container

Currently, this is a docker image based on Alpine Linux, which has [Gogs](http://gogs.io/) installed.

## Supported Architectures
This multiarch image supports `amd64`, `i386`, `arm32v6`, and `arm64v8` on Linux

## Starting the Container
`docker run -d --name gogs -p 3000:3000 -p 2222:22 whatever4711/gogs`
Thereafter you can access gogs on http://localhost:3000

## With DB and Traefik (Multiarch)

Install `docker-compose`, create a empty file called `app.ini` with, e.g. `touch app.ini`, and run `docker-compose up -d`

```[docker-compose.yml]
version: '3'

volumes:
  git:
  db:

services:
  postgres:
    image: postgres:alpine
    volumes:
      - db:/var/lib/postgresql/data
    environment:
      - POSTGRES_USER=${DB_USER:-gogs}
      - POSTGRES_PASSWORD=${DB_PASSWD:-test}
      - POSTGRES_DB=${DB_NAME:-gogs}
    labels:
      - traefik.enable=false

  gogs:
    image: whatever4711/gogs
    depends_on:
      - postgres
    volumes:
      - git:/data
      - ./app.ini:/app/gogs/custom/conf/app.ini
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.gogs-web.rule=Host(`gogs.localdomain`)"
      - "traefik.http.routers.gogs-web.entrypoints=web"
      - "traefik.http.routers.gogs-web.service=gogs-web-svc"
      - "traefik.http.services.gogs-web-svc.loadbalancer.server.port=3000"
      - "traefik.tcp.routers.gogs-ssh.rule=HostSNI(`*`)"
      - "traefik.tcp.routers.gogs-ssh.entrypoints=ssh"
      - "traefik.tcp.routers.gogs-ssh.service=gogs-ssh-svc"
      - "traefik.tcp.services.gogs-ssh-svc.loadbalancer.server.port=22"

  traefik:
    image: traefik
    command:
      #- "--log.level=DEBUG"
      - "--api=true"
      - "--api.dashboard=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.ssh.address=:2222"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    ports:
      - "80:80"
      - "2222:2222"
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik-http.entrypoints=web"
      - "traefik.http.routers.traefik-http.rule=Host(`traefik.localdomain`)"
      - "traefik.http.routers.traefik-http.service=api@internal"
```
