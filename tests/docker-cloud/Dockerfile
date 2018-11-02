# Docker image with all required dependencies to run bats in a Docker-in-Docker environment (dind)
FROM docker:stable-dind

RUN apk --no-cache add \
        bash \
        bats \
        curl \
        jq

