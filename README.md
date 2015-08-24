Jenkins DSL ready
=================

[![Join the chat at https://gitter.im/thomasleveil/docker-jenkins-dsl-ready](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/thomasleveil/docker-jenkins-dsl-ready?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Goal: **automate** your Jenkins installation. Get **Jenkins and its jobs** ready with one docker command!

This Jenkins image is based on top of the [offical Jenkins image][official-jenkins] and as such provides all its features.
Additionnaly, it comes with the **[Job DSL plugin][job-dsl] ready to use**.


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
5. The _SeedJob_, if run, creates additional jobs found in its workspace `dsl/` directory


Included plugins
----------------

- [Job DSL][job-dsl]
- [Git][git]
- [Groovy PostBuild][groovy-postbuild]
- [AnsiColor][ansicolor]
- [Rebluid][rebuild]
- [Sidebar-Link][sidebar-link]


Usage
-----

    docker run -d -p 8080:8080 -name jenkins tomdesinto/jenkins-dsl-ready

Once the _SeedJob_ is done, you will see the new jobs that were defined by the DSL scripts found in the _SeedJob_ workspace _dsl_ directory. 

Now you can edit the _SeedJob_ and make it fetch your DSL scripts from a SVN/git repository and make it create your other jobs.


DSL syntax
----------

Refer to the [DSL Job reference][dsl-job]. If you are just discovering the DSL
Plugin, you should start with the [tutorial][dsl-tutorial].

[Exemple of DSL script](https://github.com/thomasleveil/docker-jenkins-dsl-ready/blob/master/dsl/example_job_1.groovy)

Customizing the image
---------------------

You can add DSL scripts to the [`dsl/`][dsl-dir] directory. When you build the
docker image, those scripts will be stored and deployed to your Jenkins HOME 
directory when your container will be run.



[official-jenkins]: https://github.com/jenkinsci/docker/blob/master/README.md
[dsl-job]: https://github.com/jenkinsci/job-dsl-plugin/wiki/Job-reference
[dsl-tutorial]: https://github.com/jenkinsci/job-dsl-plugin/wiki/Tutorial---Using-the-Jenkins-Job-DSL
[job-dsl]: https://wiki.jenkins-ci.org/display/JENKINS/Job+DSL+Plugin
[ansicolor]: https://wiki.jenkins-ci.org/display/JENKINS/AnsiColor+Plugin
[rebuild]: https://wiki.jenkins-ci.org/display/JENKINS/Rebuild+Plugin
[git]: https://wiki.jenkins-ci.org/display/JENKINS/Git+Plugin
[sidebar-link]: https://wiki.jenkins-ci.org/display/JENKINS/Sidebar-Link+Plugin
[dsl-dir]: https://github.com/thomasleveil/docker-jenkins-dsl-ready/tree/master/dsl
[groovy-postbuild]: https://wiki.jenkins-ci.org/display/JENKINS/Groovy+Postbuild+Plugin#GroovyPostbuildPlugin-Exampleusages
[init.groovy.d]: https://wiki.jenkins-ci.org/pages/viewpage.action?pageId=70877249
[create-seed-job.groovy]: https://github.com/thomasleveil/docker-jenkins-dsl-ready/blob/master/create-seed-job.groovy