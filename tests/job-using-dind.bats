#!/usr/bin/env bats

SUT_CONTAINER=bats-jenkins-dind
DIND_CONTAINER=bats-dind

load test_helpers
load jenkins_helpers

@test "------ preparing $(basename $BATS_TEST_FILENAME .bats) ------" {
    docker kill $SUT_CONTAINER &>/dev/null ||:
    docker rm -fv $SUT_CONTAINER &>/dev/null ||:
    docker kill $DIND_CONTAINER &>/dev/null ||:
    docker rm -fv $DIND_CONTAINER &>/dev/null ||:
}

@test "dind container created" {
    local DOCKER_VERSION=$(docker --version | sed -r 's/^Docker version ([0-9.]+).*$/\1/')
    local DOCKER_DAEMON_CMD="docker daemon"
    if [[ "$(vercomp $DOCKER_VERSION '1.8.0')" = "2" ]]; then
        DOCKER_DAEMON_CMD="docker -d"
    fi
    docker run -d --name $DIND_CONTAINER \
        --privileged \
        --expose 2375 \
        dockerswarm/dind:$DOCKER_VERSION \
        $DOCKER_DAEMON_CMD -H 0.0.0.0:2375 -H unix:///var/run/docker.sock
}

@test "dind container is functionnal" {
    retry 3 1 docker exec $DIND_CONTAINER docker version
}

@test "SUT container with dind capabilities created" {
    docker run -d --name $SUT_CONTAINER \
        --link $DIND_CONTAINER:dind \
        -e DOCKER_HOST=tcp://dind:2375 \
        -v $(which docker):/usr/bin/docker:ro \
        -v $BATS_TEST_DIRNAME/resources/dsl-job-using-docker/:/usr/share/jenkins/ref/jobs/SeedJob/workspace/:ro \
        -P \
        tomdesinto/jenkins-dsl-ready
}

################################################################################

@test "Jenkins is initialized" {
    retry 30 5 jenkins_url /
}

@test "job SeedJob exists" {
    retry 5 2 jenkins_url /job/SeedJob/
}

@test "job SeedJob build #1 created" {
    retry 5 2 jenkins_url /job/SeedJob/1/
}

@test "job SeedJob last build suceeded" {
    jenkins_job_success SeedJob
}

################################################################################

@test "job test-docker created" {
    retry 5 2 jenkins_url /job/test-docker/
}

@test "build job test-docker" {
    jenkins_build_job test-docker
}

@test "job test-docker run #1 suceeded" {
    jenkins_job_success test-docker
}
