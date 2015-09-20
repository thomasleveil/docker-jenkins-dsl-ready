#!/usr/bin/env bats

SUT_CONTAINER=bats-jenkins-dind
DIND_CONTAINER=bats-dind

load lib/test_helpers

@test "------ preparing $(basename $BATS_TEST_FILENAME .bats) ------" {
    docker_clean $SUT_CONTAINER
    docker_clean $DIND_CONTAINER
}

@test "dind container created" {
    local -r DOCKER_VERSION_MINOR=$(docker --version | sed -r 's/^Docker version ([0-9]+\.[0-9]+).*$/\1/')
    docker run -d --name $DIND_CONTAINER \
        --privileged \
        docker:${DOCKER_VERSION_MINOR}-dind
}

@test "dind container is functionnal" {
    sleep 3s
    run docker_running_state $DIND_CONTAINER
    [ "$output" = "true" ] || {
        echo -e "\noutput: $output"
        echo -e "\n--------------------------------------------"
        docker logs $DIND_CONTAINER
        echo -e "--------------------------------------------\n"
    }
}

@test "SUT container with dind capabilities created" {
    docker run -d --name $SUT_CONTAINER \
        --link $DIND_CONTAINER:dind \
        -e DOCKER_HOST=tcp://dind:2375 \
        $DOCKER_OPTS_ENABLING_DOCKER \
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
    jenkins_job_success SeedJob || {
        echo -e "\n\n---------------------------------------------------------"
        curl --silent --fail $(get_jenkins_url)/job/SeedJob/lastBuild/consoleText
        echo -e "---------------------------------------------------------\n\n"
        false
    }
}

################################################################################

@test "job test-docker created" {
    retry 5 2 jenkins_url /job/test-docker/
}

@test "build job test-docker" {
    jenkins_build_job test-docker
}

@test "job test-docker run #1 suceeded" {
    jenkins_job_success test-docker || {
        echo -e "\n\n---------------------------------------------------------"
        curl --silent --fail $(get_jenkins_url)/job/test-docker/lastBuild/consoleText
        echo -e "---------------------------------------------------------\n\n"
        false
    }
}
