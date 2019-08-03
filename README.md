Jenkins DSL ready
=================

[![](https://images.microbadger.com/badges/image/tomdesinto/jenkins-dsl-ready.svg)](https://microbadger.com/images/tomdesinto/jenkins-dsl-ready "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/tomdesinto/jenkins-dsl-ready.svg)](https://microbadger.com/images/tomdesinto/jenkins-dsl-ready "Get your own version badge on microbadger.com")
[![Build Status](https://travis-ci.org/thomasleveil/docker-jenkins-dsl-ready.svg?branch=master)](https://travis-ci.org/thomasleveil/docker-jenkins-dsl-ready)

[![DockerHub Badge](http://dockeri.co/image/tomdesinto/jenkins-dsl-ready)](https://hub.docker.com/r/tomdesinto/jenkins-dsl-ready/)

Goal: **automate** your Jenkins installation. Get **Jenkins and its jobs** ready with one docker command!

This Jenkins image is based on top of the [official Jenkins image][official-jenkins] and as such provides all its features.
Additionally, it comes with the **[Job DSL][job-dsl] and [Jenkins Configuration as Code](https://github.com/jenkinsci/configuration-as-code-plugin) plugins ready to use**.


tl;dr
-----

    docker run -d -p 8080:8080 tomdesinto/jenkins-dsl-ready

    docker run -d -p 8080:8080 -v /your/dsl/files/:/usr/share/jenkins/ref/jobs/SeedJob/workspace/:ro tomdesinto/jenkins-dsl-ready

    docker run -d -p 8080:8080 -e SEEDJOB_GIT=https://your.repo.git tomdesinto/jenkins-dsl-ready

    docker run -d -p 8080:8080 -e SEEDJOB_SVN=svn://your.repo tomdesinto/jenkins-dsl-ready

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
- [Jenkins Configuration as Code (JCasC)][configuration-as-code]
- [Pipeline][workflow-aggregator]
- [CloudBees Docker Pipeline][docker-workflow]
- [Git][git]
- [Subversion (SVN)][subversion]
- [GitHub][github]
- [GitHub pull request builder][ghprb]
- [Config File Provider][config-file-provider]
- [Groovy PostBuild][groovy-postbuild]
- [AnsiColor][ansicolor]
- [Rebuild][rebuild]
- [Sidebar-Link][sidebar-link]
- [Build-timeout][build-timeout]
- [Cobertura][cobertura]
- [Copy Artifact][copyartifact]
- [Description Setter][description-setter]
- [Email-ext][email-ext]
- [Gradle][gradle]
- [Parameterized  Trigger][parameterized-trigger]
- [Publish Over Ssh][publish-over-ssh]
- [Warnings][warnings]
- [Workspace Cleanup][ws-cleanup]


_See the full list of plugins in the [plugins.txt](plugins.txt) file._


Usage
-----

### Jenkins Configuration as Code (JCasC)

The [Jenkins Configuration as Code Plugin](https://github.com/jenkinsci/configuration-as-code-plugin) provides an convenient way to configure Jenkins and some plugins from simple yaml files.

Provide those yaml files to the container with a volume mounted to the `/var/jenkins_home/casc_configs/` directory:

    docker run -d -p 8080:8080 -v /my/JCasC/jenkins.yml:/var/jenkins_home/casc_configs/jenkins.yml tomdesinto/jenkins-dsl-ready


### Default DSL jobs

By running the image as follow:

    docker run -d -p 8080:8080 tomdesinto/jenkins-dsl-ready

You will end up with an instance of Jenkins that demonstrates the usage of the DSL plugin. In this configuration you will have 2 default jobs created additionally to the _SeedJob_.

From there you can edit the _SeedJob_ and make it fetch your DSL scripts from a SVN/git repository and make it create your other jobs.

### Providing DSL jobs with Git/SVN

If you want to provide the DSL scripts from a remote repository, use either the `SEEDJOB_GIT` or `SEEDJOB_SVN` environment variables.

    docker run -d -p 8080:8080 -e SEEDJOB_GIT=https://your.repo.git tomdesinto/jenkins-dsl-ready
    docker run -d -p 8080:8080 -e SEEDJOB_SVN=svn://your.repo tomdesinto/jenkins-dsl-ready

### Providing DSL jobs from a directory

You can provide you groovy DSL files from a directory on your docker host by mounting this directory with a docker volume on `/usr/share/jenkins/ref/jobs/SeedJob/workspace/`.

    docker run -d -p 8080:8080 -v /somewhere/on/your/host/dsl/:/usr/share/jenkins/ref/jobs/SeedJob/workspace/:ro tomdesinto/jenkins-dsl-ready

### Using Docker within jobs

#### Method 1 - Sharing the jenkins-dsl-ready Docker Host engine (root)

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


#### Method 2 - Sharing the jenkins-dsl-ready Docker Host engine (sudo)

Same as method 2, but we don't run Jenkins as _root_. In this case the Jenkins jobs will have to use `sudo docker` instead of just `docker`:

    docker run -d \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -p 8080:8080 \
        --name jenkins \
        tomdesinto/jenkins-dsl-ready

In this setup, you can use docker with sudo: `sudo docker`.

Care should be given to files rights in Jenkins jobs. If a job makes use of `sudo` to run a command which will write files in the job workspace, those files
will be owned by _root_. Jenkins would then be unable to manage then (wipe workspace, clear, etc) unless your job also makes sure to call `chown jenkins` on them.


#### Method 3 - Using dind (Docker in Docker)

Using the official [docker:dind][dind] image, you can start a container which runs another _child_ Docker engine which will be available to your jenkins-dsl-ready container through links. Be aware of constraints and pitfalls that comes with such a setup. Make sure to read [Using Docker-in-Docker for your CI or testing environment? Think twice](https://jpetazzo.github.io/2015/09/03/do-not-use-docker-in-docker-for-ci/) from Jérôme Petazzoni.

    docker run -d --name dind \
        --privileged \
        -e DOCKER_DRIVER=overlay2 \
        -e DOCKER_TLS_CERTDIR='' \
        -e DOCKER_HOST=tcp://docker-daemon:2375 \
        docker:19.03-dind

**note:** use the tag that matches your docker version. i.e.: `docker:1.8-dind` if you have docker `v1.8.1` or `v1.8.2`. `docker:1.7-dind` if you have docker `v1.7.x`, and so on. See available tags at https://hub.docker.com/r/library/docker/tags/

You would then start the jenkins-dsl-ready container with:

    docker run -d \
        -p 8080:8080 \
        --link dind:dind \
        -e DOCKER_HOST=tcp://dind:2375 \
        --name jenkins \
        tomdesinto/jenkins-dsl-ready

From now on, you can call directly the `docker` command within Jenkins jobs.

#### Troubleshooting

If docker fails with error `Error response from daemon: client is newer than server (client API version: 1.20, server API version: 1.19)`, or similar, then
it means the version of the Docker client from the jenkins-dsl-ready image is newer than the Docker engine from the dind image. Refer to the _note_ above to start a dind container having the right version of docker.

If docker fails with error `docker: error while loading shared libraries: libapparmor.so.1: cannot open shared object file: No such file or directory`, then you need to mount another volume on your container to enable the docker process to use the appArmor shared libraries. Depending on your system, the exact location of the librairies might differ from the following example: `-v /usr/lib/x86_64-linux-gnu/libapparmor.so.1.1.0:/usr/lib/x86_64-linux-gnu/libapparmor.so.1`. More info at [https://github.com/SvenDowideit/dockerfiles/issues/17](https://github.com/SvenDowideit/dockerfiles/issues/17).


DSL syntax
----------

Refer to the [DSL Job reference][dsl-job]. If you are just discovering the DSL
Plugin, you should start with the [tutorial][dsl-tutorial].

[Example of DSL script](https://github.com/thomasleveil/docker-jenkins-dsl-ready/blob/master/dsl/example_job_1.groovy)


Customizing the Docker image
----------------------------

You can build your own version of the Docker image to custimize it.


### Add different default DSL files

You can add default DSL scripts to the [`dsl/`][dsl-dir] directory. When you build the docker image, those scripts will be copied to the _SeedJob_ workspace when the container will be run.



### Add more Jenkins plugins

Just edit the [plugins.txt](plugins.txt) file. This file must contain one Jenkins plugin id per line. You can find the plugins' id on the official [Jenkins plugins website](https://plugins.jenkins.io/).

For instance, to add the [Green Balls](https://plugins.jenkins.io/greenballs) plugin, add a line with `greenballs`.

You can pin a specific version for plugins with this syntax: `greenballs:1.15`



### Add software and dependencies

Your jobs might depend on software which is not available in this image. You can build your own image with additional software by adding the commands to install them after the _customize below_ section.

    ###############################################################################
    ##                          customize below                                  ##
    ###############################################################################

    # Eventually place here any `apt-get install` command to add tools to the image
    #


    # COPY your Seed Job DSL script
    COPY dsl/*.groovy /usr/share/jenkins/ref/jobs/SeedJob/workspace/


[ansicolor]: https://plugins.jenkins.io/ansicolor
[build-timeout]: https://plugins.jenkins.io/build-timeout
[cobertura]: https://plugins.jenkins.io/cobertura
[config-file-provider]: https://plugins.jenkins.io/config-file-provider
[configuration-as-code]: https://plugins.jenkins.io/configuration-as-code
[copyartifact]: https://plugins.jenkins.io/copyartifact
[create-seed-job.groovy]: https://github.com/thomasleveil/docker-jenkins-dsl-ready/blob/master/build/create-seed-job.groovy
[description-setter]: https://plugins.jenkins.io/description-setter
[dind]: https://hub.docker.com/r/dockerswarm/dind/
[docker-rm]: https://docs.docker.com/reference/commandline/rm/
[docker-workflow]: https://plugins.jenkins.io/docker-workflow
[dsl-dir]: https://github.com/thomasleveil/docker-jenkins-dsl-ready/tree/master/dsl
[dsl-job]: https://jenkinsci.github.io/job-dsl-plugin/
[dsl-tutorial]: https://github.com/jenkinsci/job-dsl-plugin/wiki/Tutorial---Using-the-Jenkins-Job-DSL
[email-ext]: https://plugins.jenkins.io/email-ext
[ghprb]: https://plugins.jenkins.io/ghprb
[git]: https://plugins.jenkins.io/git
[github]: https://plugins.jenkins.io/github
[gradle]: https://plugins.jenkins.io/gradle
[groovy-postbuild]: https://plugins.jenkins.io/groovy-postbuild
[init.groovy.d]: https://plugins.jenkins.io/init.groovy.d
[job-dsl]: https://plugins.jenkins.io/job-dsl
[official-jenkins]: https://github.com/jenkinsci/docker/blob/master/README.md
[parameterized-trigger]: https://plugins.jenkins.io/parameterized-trigger
[publish-over-ssh]: https://plugins.jenkins.io/publish-over-ssh
[rebuild]: https://plugins.jenkins.io/rebuild
[sidebar-link]: https://plugins.jenkins.io/sidebar-link
[subversion]: https://plugins.jenkins.io/subversion
[warnings]:  https://plugins.jenkins.io/warnings
[workflow-aggregator]: https://plugins.jenkins.io/workflow-aggregator
[ws-cleanup]: https://plugins.jenkins.io/ws-cleanup
