[![CircleCI](https://circleci.com/gh/whatever4711/docker-gogs.svg?style=svg)](https://circleci.com/gh/whatever4711/docker-gogs)

[![](https://images.microbadger.com/badges/version/whatever4711/gogs.svg)](https://microbadger.com/images/whatever4711/gogs "Get your own version badge on microbadger.com")  [![](https://images.microbadger.com/badges/image/whatever4711/gogs.svg)](https://microbadger.com/images/whatever4711/gogs "Get your own image badge on microbadger.com")

# Gogs in a Container

Currently, this is a docker image based on Alpine Linux, which has [Gogs](http://gogs.io/) installed.

## Supported Architectures
This multiarch image supports `amd64`, `arm32v6` and `arm64v8` on Linux

## Starting the Container
`docker run -d --name gogs -p 3000:3000 -p 2222:22 whatever4711/gogs`
Thereafter you can access gogs on http://localhost:3000
