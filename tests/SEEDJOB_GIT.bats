#!/usr/bin/env bats

SUT_CONTAINER=bats-jenkins-git
GIT_CONTAINER=bats-git

load test_helpers
load jenkins_helpers

@test "------ preparing $(basename $BATS_TEST_FILENAME .bats) ------" {
    docker kill $SUT_CONTAINER &>/dev/null ||:
    docker rm -fv $SUT_CONTAINER &>/dev/null ||:
    docker kill $GIT_CONTAINER &>/dev/null ||:
    docker rm -fv $GIT_CONTAINER &>/dev/null ||:
}

@test "setup a Git server" {
    docker run -d --name $GIT_CONTAINER -w /data --expose 9418 yesops/git bash -c "
        git init --bare && git daemon --export-all --enable=receive-pack
    "
    sleep 2
    docker run --rm -t --link $GIT_CONTAINER:gitserver yesops/git bash -c "
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

@test "SUT container with SEEDJOB_GIT created" {
    docker run -d --name $SUT_CONTAINER -P \
        --link $GIT_CONTAINER:gitserver \
        -e SEEDJOB_GIT=git://gitserver/data \
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

@test "job 'job-from-git' exists" {
    retry 15 1 jenkins_url /job/job-from-git/
}
