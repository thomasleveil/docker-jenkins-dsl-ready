#!/usr/bin/env bats

SUT_CONTAINER=bats-jenkins-svn
SVN_CONTAINER=bats-svn

load test_helpers
load jenkins_helpers

@test "clean test containers" {
    docker kill $SUT_CONTAINER &>/dev/null ||:
    docker rm -fv $SUT_CONTAINER &>/dev/null ||:
    docker kill $SVN_CONTAINER &>/dev/null ||:
    docker rm -fv $SVN_CONTAINER &>/dev/null ||:
}

@test "setup a SVN server" {
    docker run -d --name $SVN_CONTAINER erikxiv/subversion
    sleep 2
    docker run --rm --link $SVN_CONTAINER:svnserver erikxiv/subversion bash -c "
        echo \"job('job-from-svn') {}\" > job-from-svn.groovy
        svn import job-from-svn.groovy svn://svnserver/repos/job-from-svn.groovy -m 'first import'
    "
}

@test "SUT container with SEEDJOB_SVN created" {
    docker run -d --name $SUT_CONTAINER -P \
        --link $SVN_CONTAINER:svnserver \
        -e SEEDJOB_SVN=svn://svnserver/repos \
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

@test "job 'job-from-svn' exists" {
    retry 15 1 jenkins_url /job/job-from-svn/
}
