#!/usr/bin/env bats

SUT_CONTAINER=bats-jenkins-git
GIT_CONTAINER=bats-git

load lib/test_helpers

@test "------ preparing $(basename $BATS_TEST_FILENAME .bats) ------" {
    docker_clean $SUT_CONTAINER
    docker_clean $GIT_CONTAINER
}

@test "setup a Git server" {
    docker run -d --name $GIT_CONTAINER -w /data --expose 9418 --entrypoint /bin/sh alpine/git -c "
        apk --no-cache add git-daemon
        git init --bare
        git daemon --export-all --enable=receive-pack
    "
    sleep 5
    retry 10 5 docker run --rm -t --link $GIT_CONTAINER:gitserver --entrypoint /bin/sh alpine/git -c "
        git config --global user.email 'you@example.com'
        git config --global user.name 'Your Name'
        git clone git://gitserver/data
        cd data
        echo \"job('job_from_git') {}\" > job_from_git.groovy
        git add job_from_git.groovy
        git commit -m 'first import'
        git push origin master
    "
}

@test "SUT container with SEEDJOB_GIT created" {
    docker run -d --name $SUT_CONTAINER -P \
        --link $GIT_CONTAINER:gitserver \
        -e SEEDJOB_GIT=git://gitserver/data \
        $SUT_IMAGE
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

@test "job 'job_from_git' exists" {
    retry 15 1 jenkins_url /job/job_from_git/
}
