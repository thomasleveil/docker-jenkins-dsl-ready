Jenkins DSL ready
=================

[![](https://badge.imagelayers.io/tomdesinto/jenkins-dsl-ready:latest.svg)](https://imagelayers.io/?images=tomdesinto/jenkins-dsl-ready:latest 'Get your own badge on imagelayers.io')
[![Build Status](https://travis-ci.org/thomasleveil/docker-jenkins-dsl-ready.svg?branch=master)](https://travis-ci.org/thomasleveil/docker-jenkins-dsl-ready)
[![Join the chat at https://gitter.im/thomasleveil/docker-jenkins-dsl-ready](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/thomasleveil/docker-jenkins-dsl-ready?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Goal: **automate** your Jenkins installation. Get **Jenkins and its jobs** ready with one docker command!

This Jenkins image is based on top of the [official Jenkins image][official-jenkins] and as such provides all its features.
Additionally, it comes with the **[Job DSL plugin][job-dsl] ready to use**.


tl;dr
-----

    docker run -d -p 8080:8080 -name jenkins tomdesinto/jenkins-dsl-ready


What does it do?
----------------

When you start the container the following happens:

1. All elements (plugins, jobs, config, etc) from `/usr/share/jenkins/ref/` which are not yet in `$JENKINS_HOME` are copied over
2. Jenkins starts
3. all Groovy scripts found in [$JENKINS_HOME/init.groovy.d/][init.groovy.d] are run, which includes our [create-seed-job.groovy script][create-seed-job.groovy]
4. The _SeedJob_ is eventually created and a run is scheduled if it was missing
5. The _SeedJob_, if run, creates additional jobs found in its workspace:
  - by default the groovy scripts are provided by the docker image (see the `dsl/` directory content)
  - if a git repository url is provided with the `SEEDJOB_GIT` environment variable, the _SeedJob_ will fetch the groovy scripts from there
  - else if a svn repository url is provided with the `SEEDJOB_SVN` environment variable, the _SeedJob_ will fetch the groovy scripts from there


Included plugins
----------------

- [Job DSL][job-dsl]
- [Git][git]
- [GitHub][github]
- [Config File Provider][config-file-provider]
- [Groovy PostBuild][groovy-postbuild]
- [AnsiColor][ansicolor]
- [Rebluid][rebuild]
- [Sidebar-Link][sidebar-link]
- [Build-timeout][build-timeout]
- [Cobertura][cobertura]
- [Copy Artifact][copyartifact]
- [Description Setter][description-setter]
- [Email-ext][email-ext]
- [GitHub pull request builder][ghprb]
- [Gradle][gradle]
- [Parameterized  Trigger][parameterized-trigger]
- [Publish Over Ssh][publish-over-ssh]
- [Warnings][warnings]
- [Workspace Cleanup][ws-cleanup]


Usage
-----

    docker run -d -p 8080:8080 tomdesinto/jenkins-dsl-ready

Once the _SeedJob_ is done, you will see the new jobs that were defined by the DSL scripts found in the _SeedJob_ workspace. 

Now you can edit the _SeedJob_ and make it fetch your DSL scripts from a SVN/git repository and make it create your other jobs.

If you want to provide the DSL scripts from a remote repository use one of the following forms:

    docker run -d -p 8080:8080 -e SEEDJOB_GIT=https://your.repo.git tomdesinto/jenkins-dsl-ready
    docker run -d -p 8080:8080 -e SEEDJOB_SVN=svn://your.repo tomdesinto/jenkins-dsl-ready

or from a directory on your docker host:

    docker run -d -p 8080:8080 -v /somewhere/on/your/host/dsl/:/usr/share/jenkins/ref/jobs/SeedJob/workspace/:ro tomdesinto/jenkins-dsl-ready


### Using Docker within jobs

#### Method 1 - Using dind (Docker in Docker)

Using the [dockerswarm/dind][dind] image, you can start a container which run another Docker engine, and make this new engine available to your jenkins-dsl-ready container through links:

    docker run -d \
        --privileged \
        --expose 2375 \
        --name dind \
        dockerswarm/dind:1.8.1 \
        docker daemon -H 0.0.0.0:2375 -H unix:///var/run/docker.sock

**note:** use the `dockerswarm/dind` tag that matches your docker version. i.e.: `dockerswarm/dind:1.8.1` if you have docker `v1.8.1`.

**note2:** before docker v1.8.0, the command to run the daemon is `docker -d` instead of `docker daemon`.

You would then start the jenkins-dsl-ready container with:

    docker run -d \
        -p 8080:8080 \
        --link dind:dind \
        -e DOCKER_HOST=tcp://dind:2375 \
        --name jenkins \
        tomdesinto/jenkins-dsl-ready

From now on, you can call directly the `docker` command.

If docker fails with error `Error response from daemon: client is newer than server (client API version: 1.20, server API version: 1.19)`, or similar, then
it means the version of the Docker client from the jenkins-dsl-ready image is newer than the Docker engine from the dind image.
In that case you should [build][github-dind] yourself the dind image to get a more up-to-date version of the Docker engine.

For other Docker errors, refer to the [dind README file][dind-troubleshooting].

Note on disk usage: dind uses a docker volume for its Docker engine data (docker images/containers/volumes). To reclaim that space, you have to use the `-v` option of the [`docker rm`][docker-rm] command.


#### Method 2 - Sharing the jenkins-dsl-ready Docker Host engine (root)

If you want your jobs to be able to make use of the Docker engine running on the Jenkins container host, first note that this is **insecure** as any Jenkins jobs will be able to take control of the full Docker engine (meaning even deleting any image/container on the Docker host), then you need to start the _jenkins-dsl-ready_ container a bit differently:

- Jenkins must be run by the user _root_
- The `/var/run/docker.sock` socket file must be mounted as a volume

In the end, the command to run such a container is:

    docker run -d \
        -u root \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -p 8080:8080 \
        --name jenkins \
        tomdesinto/jenkins-dsl-ready

From now on, you can call directly the `docker` command.


#### Method 3 - Sharing the jenkins-dsl-ready Docker Host engine (sudo)

Same as method 2, but we don't run Jenkins as _root_. In this case the Jenkins jobs will have to use `sudo docker` instead of just `docker`:

    docker run -d \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -p 8080:8080 \
        --name jenkins \
        tomdesinto/jenkins-dsl-ready

In this setup, you can use docker with sudo: `sudo docker`.

Care should be given to files rights in Jenkins jobs. If a job makes use of `sudo` to run a command which will write files in the job workspace, those files
will be owned by _root_. Jenkins would then be unable to manage then (wipe workspace, clear, etc) unless your job also makes sure to call `chown jenkins` on them.


DSL syntax
----------

Refer to the [DSL Job reference][dsl-job]. If you are just discovering the DSL
Plugin, you should start with the [tutorial][dsl-tutorial].

[Example of DSL script](https://github.com/thomasleveil/docker-jenkins-dsl-ready/blob/master/dsl/example_job_1.groovy)


Customizing the image
---------------------

You can add DSL scripts to the [`dsl/`][dsl-dir] directory. When you build the
docker image, those scripts will be copied to the _SeedJob_ workspace when the container will be run.



[official-jenkins]: https://github.com/jenkinsci/docker/blob/master/README.md
[dsl-job]: https://github.com/jenkinsci/job-dsl-plugin/wiki/Job-reference
[dsl-tutorial]: https://github.com/jenkinsci/job-dsl-plugin/wiki/Tutorial---Using-the-Jenkins-Job-DSL
[dsl-dir]: https://github.com/thomasleveil/docker-jenkins-dsl-ready/tree/master/dsl
[init.groovy.d]: https://wiki.jenkins-ci.org/pages/viewpage.action?pageId=70877249
[create-seed-job.groovy]: https://github.com/thomasleveil/docker-jenkins-dsl-ready/blob/master/create-seed-job.groovy
[docker-rm]: https://docs.docker.com/reference/commandline/rm/
[github-dind]: https://github.com/aluzzardi/dind
[dind]: https://hub.docker.com/r/dockerswarm/dind/
[dind-troubleshooting]: https://github.com/jpetazzo/dind#it-didnt-work
[job-dsl]: https://wiki.jenkins-ci.org/display/JENKINS/Job+DSL+Plugin
[ansicolor]: https://wiki.jenkins-ci.org/display/JENKINS/AnsiColor+Plugin
[rebuild]: https://wiki.jenkins-ci.org/display/JENKINS/Rebuild+Plugin
[git]: https://wiki.jenkins-ci.org/display/JENKINS/Git+Plugin
[sidebar-link]: https://wiki.jenkins-ci.org/display/JENKINS/Sidebar-Link+Plugin
[groovy-postbuild]: https://wiki.jenkins-ci.org/display/JENKINS/Groovy+Postbuild+Plugin#GroovyPostbuildPlugin-Exampleusages
[github]: https://wiki.jenkins-ci.org/display/JENKINS/GitHub+Plugin
[config-file-provider]: https://wiki.jenkins-ci.org/display/JENKINS/Config+File+Provider+Plugin
[build-timeout]: https://wiki.jenkins-ci.org/display/JENKINS/Build-timeout+Plugin
[cobertura]: https://wiki.jenkins-ci.org/display/JENKINS/Cobertura+Plugin
[copyartifact]: https://wiki.jenkins-ci.org/display/JENKINS/Copy+Artifact+Plugin
[description-setter]: https://wiki.jenkins-ci.org/display/JENKINS/Description+Setter+Plugin
[email-ext]: https://wiki.jenkins-ci.org/display/JENKINS/Email-ext+plugin
[ghprb]: https://wiki.jenkins-ci.org/display/JENKINS/GitHub+pull+request+builder+plugin
[gradle]: https://wiki.jenkins-ci.org/display/JENKINS/Gradle+Plugin
[parameterized-trigger]: https://wiki.jenkins-ci.org/display/JENKINS/Parameterized+Trigger+Plugin
[publish-over-ssh]: https://wiki.jenkins-ci.org/display/JENKINS/Publish+Over+SSH+Plugin
[warnings]:  https://wiki.jenkins-ci.org/display/JENKINS/Warnings+Plugin
[ws-cleanup]: https://wiki.jenkins-ci.org/display/JENKINS/Workspace+Cleanup+Plugin