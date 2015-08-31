#!/usr/bin/env bats

load test_helpers

@test "eventually clean test containers" {
    docker kill bats-jenkins-git bats-git &>/dev/null ||:
    docker rm -fv bats-jenkins-git bats-git &>/dev/null ||:
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

@test "container tomdesinto/jenkins-dsl-ready with SEEDJOB_GIT is running" {
    docker run -d --name bats-jenkins-git -P \
        --link bats-git:gitserver \
        -e SEEDJOB_GIT=git://gitserver/data \
        tomdesinto/jenkins-dsl-ready
}

@test "Jenkins is initialized" {
    sleep 20
    wait_for_jenkins bats-jenkins-git
    test_url bats-jenkins-git /
}

@test "job SeedJob exists" {
    sleep 1
    test_url bats-jenkins-git /job/SeedJob/
}

@test "job 'job-from-git' exists" {
    sleep 5
    test_url bats-jenkins-git /job/job-from-git/
}
