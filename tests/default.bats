#!/usr/bin/env bats

SUT_CONTAINER=bats-jenkins

load test_helpers
load jenkins_helpers

@test "------ preparing $(basename $BATS_TEST_FILENAME .bats) ------" {
    docker kill $SUT_CONTAINER &>/dev/null ||:
    docker rm -fv $SUT_CONTAINER &>/dev/null ||:
}

@test "SUT container created" {
    docker run -d --name $SUT_CONTAINER -P tomdesinto/jenkins-dsl-ready
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

@test "job 'Example 1' exists" {
    retry 15 1 jenkins_url /job/Example%201/
}

@test "job 'Example with docker' exists" {
    retry 15 1 jenkins_url /job/Example%20with%20docker/
}
