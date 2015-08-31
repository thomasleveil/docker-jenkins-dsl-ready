#!/usr/bin/env bats

load test_helpers

@test "eventually clean test containers" {
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

@test "container tomdesinto/jenkins-dsl-ready with SEEDJOB_SVN is running" {
    docker run -d --name bats-jenkins-svn -P \
        --link bats-svn:svnserver \
        -e SEEDJOB_SVN=svn://svnserver/repos \
        tomdesinto/jenkins-dsl-ready
}

@test "Jenkins is initialized" {
    sleep 20
    wait_for_jenkins bats-jenkins-svn
    test_url bats-jenkins-svn /
}

@test "job SeedJob exists" {
    sleep 1
    test_url bats-jenkins-svn /job/SeedJob/
}

@test "job 'job-from-svn' exists" {
    sleep 5
    test_url bats-jenkins-svn /job/job-from-svn/
}
