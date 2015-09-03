#!/usr/bin/env bats

SUT_CONTAINER=bats-jenkins-svn

load test_helpers

@test "clean test containers" {
    docker kill bats-jenkins-svn bats-svn &>/dev/null ||:
    docker rm -fv bats-jenkins-svn bats-svn &>/dev/null ||:
}

@test "setup a SVN server" {
    docker run -d --name bats-svn erikxiv/subversion
    sleep 2
    docker run --rm --link bats-svn:svnserver erikxiv/subversion bash -c "
        echo \"job('job-from-svn') {}\" > job-from-svn.groovy
        svn import job-from-svn.groovy svn://svnserver/repos/job-from-svn.groovy -m 'first import'
    "
}

@test "container tomdesinto/jenkins-dsl-ready with SEEDJOB_SVN created" {
    docker run -d --name bats-jenkins-svn -P \
        --link bats-svn:svnserver \
        -e SEEDJOB_SVN=svn://svnserver/repos \
        tomdesinto/jenkins-dsl-ready
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
    retry 10 1 curl -sS $url | jq --exit-status '.building==false'
    
    assert '"SUCCESS"' curl -sS $url | jq '.result'
}

@test "job 'job-from-svn' exists" {
    retry 15 1 test_url /job/job-from-svn/api/json
}
