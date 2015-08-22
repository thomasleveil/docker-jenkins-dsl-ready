Jenkins DSL ready
=================

This Jenkins image is based on top of the [offical Jenkins image][official-jenkins] and as such provides all its features.

Additionnaly, this image comes with the [Job DSL plugin][job-dsl] ready to use.

Included plugins
----------------

- [Job DSL][job-dsl]
- [Git][git]
- [AnsiColor][ansicolor]
- [Rebluid][rebuild]
- [Sidebar-Link][sidebar-link]


Usage
-----

1. start the docker container

        docker run -d -p 8080:8080 -name jenkins tomdesinto/jenkins-dsl-ready

2. Wait for Jenkins to be up
3. Run the _SeedJob_ job

Once the _SeedJob_ is done, you will see a new job. Now you can edit the _SeedJob_ and make it fetch your DSL scripts from a SVN/git repository and 
make it create your jobs.


DSL syntax
----------

Refer to the [DSL Job reference][dsl-job]. If you are just discovering the DSL
Plugin, you should start with the [tutorial][dsl-tutorial].



[official-jenkins]: https://github.com/jenkinsci/docker/blob/master/README.md
[dsl-job]: https://github.com/jenkinsci/job-dsl-plugin/wiki/Job-reference
[dsl-tutorial]: https://github.com/jenkinsci/job-dsl-plugin/wiki/Tutorial---Using-the-Jenkins-Job-DSL
[job-dsl]: https://wiki.jenkins-ci.org/display/JENKINS/Job+DSL+Plugin
[ansicolor]: https://wiki.jenkins-ci.org/display/JENKINS/AnsiColor+Plugin
[rebuild]: https://wiki.jenkins-ci.org/display/JENKINS/Rebuild+Plugin
[git]: https://wiki.jenkins-ci.org/display/JENKINS/Git+Plugin
[sidebar-link]: https://wiki.jenkins-ci.org/display/JENKINS/Sidebar-Link+Plugin
