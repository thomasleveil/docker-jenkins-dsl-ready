FROM docker:stable-dind

RUN apk --no-cache add \
        bash \
        bats \
        curl \
        jq

COPY ./run-tests.sh /
