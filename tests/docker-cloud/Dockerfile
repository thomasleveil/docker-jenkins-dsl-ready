FROM docker:stable-dind

RUN apk --update --no-cache-dir add \
        bash \
        bats \
        curl \
        jq

COPY ./run-tests.sh /
