# Gogs in a Container

Currently, this is a docker image based on Alpine Linux, which has [Gogs](http://gogs.io/) installed.

## Supported Architectures
This multiarch image supports `amd64`, `arm32v6` and `arm64v8` on Linux

## Starting the Container
`docker run -d --name gogs -p 3000:3000 -p 2222:22 whatever4711/gogs`
Thereafter you can access gogs on http://localhost:3000
