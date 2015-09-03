#!/usr/bin/env bats

SUT_CONTAINER=bats-jenkins

load test_helpers

@test "clean test containers" {
    docker kill $SUT_CONTAINER &>/dev/null ||:
    docker rm -fv $SUT_CONTAINER &>/dev/null ||:
}

@test "container tomdesinto/jenkins-dsl-ready created" {
    docker run -d --name $SUT_CONTAINER -P tomdesinto/jenkins-dsl-ready
}

@test "Jenkins is initialized" {
    retry 30 5 test_url /api/json
}

@test "job SeedJob exists" {
    retry 5 2 test_url /job/SeedJob/api/json
}

@test "job SeedJob run #1 created" {
    retry 5 2 test_url /job/SeedJob/1/api/json
}

@test "job SeedJob run #1 suceeded" {
    jq_is_available_or_skip
    local url=$(get_jenkins_url)/job/SeedJob/1/api/json

    # wait while job is running
    retry 10 3 curl -sS $url | jq --exit-status '.building==false'
    
    assert '"SUCCESS"' curl -sS $url | jq '.result'
}

@test "job 'Example 1' exists" {
    retry 15 1 test_url /job/Example%201/api/json
}

@test "job 'Example with docker' exists" {
    retry 15 1 test_url /job/Example%20with%20docker/api/json
}
