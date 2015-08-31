#!/usr/bin/env bats

load test_helpers

@test "eventually clean test containers" {
    docker kill bats-jenkins &>/dev/null ||:
    docker rm -fv bats-jenkins &>/dev/null ||:
}

@test "container tomdesinto/jenkins-dsl-ready is running" {
    docker run -d --name bats-jenkins -P tomdesinto/jenkins-dsl-ready
}

@test "Jenkins is initialized" {
    sleep 20
    wait_for_jenkins bats-jenkins
    test_url bats-jenkins /
}

@test "job SeedJob exists" {
    sleep 1
    test_url bats-jenkins /job/SeedJob/
}

@test "job 'Example 1' exists" {
    sleep 5
    test_url bats-jenkins /job/Example%201/
}

@test "job 'Example with docker' exists" {
    test_url bats-jenkins /job/Example%20with%20docker/
}
