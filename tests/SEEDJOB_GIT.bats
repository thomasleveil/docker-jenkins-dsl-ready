#!/usr/bin/env bats

SUT_CONTAINER=bats-jenkins-git

load test_helpers

@test "clean test containers" {
    docker kill $SUT_CONTAINER bats-git &>/dev/null ||:
    docker rm -fv $SUT_CONTAINER bats-git &>/dev/null ||:
}

@test "setup a Git server" {
    docker run -d --name bats-git -w /data --expose 9418 yesops/git bash -c "
        git init --bare && git daemon --export-all --enable=receive-pack
    "
    sleep 2
    docker run --rm -t --link bats-git:gitserver yesops/git bash -c "
        git config --global user.email 'you@example.com'
        git config --global user.name 'Your Name'
        git clone git://gitserver/data
        cd data
        echo \"job('job-from-git') {}\" > job-from-git.groovy
        git add job-from-git.groovy
        git commit -m 'first import'
        git push origin master
    "
}

@test "container tomdesinto/jenkins-dsl-ready with SEEDJOB_GIT created" {
    docker run -d --name $SUT_CONTAINER -P \
        --link bats-git:gitserver \
        -e SEEDJOB_GIT=git://gitserver/data \
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

@test "job 'job-from-git' exists" {
    retry 15 1 test_url /job/job-from-git/api/json
}
