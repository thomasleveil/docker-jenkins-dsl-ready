FROM jenkins

ENV PLUGINS_DL_URL http://updates.jenkins-ci.org/download/plugins

# Install plugins
COPY ${PLUGINS_DL_URL}/job-dsl/latest/job-dsl.hpi                               /usr/share/jenkins/ref/plugins/
COPY ${PLUGINS_DL_URL}/git/latest/git.hpi                                       /usr/share/jenkins/ref/plugins/
COPY ${PLUGINS_DL_URL}/git-client/latest/git-client.hpi                         /usr/share/jenkins/ref/plugins/
COPY ${PLUGINS_DL_URL}/scm-api/latest/scm-api.hpi                               /usr/share/jenkins/ref/plugins/
COPY ${PLUGINS_DL_URL}/parameterized-trigger/latest/parameterized-trigger.hpi   /usr/share/jenkins/ref/plugins/
COPY ${PLUGINS_DL_URL}/ansicolor/latest/ansicolor.hpi                           /usr/share/jenkins/ref/plugins/
COPY ${PLUGINS_DL_URL}/rebuild/latest/rebuild.hpi                               /usr/share/jenkins/ref/plugins/
COPY ${PLUGINS_DL_URL}/sidebar-link/latest/sidebar-link.hpi                     /usr/share/jenkins/ref/plugins/
COPY ${PLUGINS_DL_URL}/groovy-postbuild/latest/groovy-postbuild.hpi             /usr/share/jenkins/ref/plugins/

# Groovy script to create the "SeedJob" (the standard way, not with DSL)
COPY create-seed-job.groovy /usr/share/jenkins/ref/init.groovy.d/

# The place where to put the DSL files for the Seed Job to run
RUN mkdir -p /usr/share/jenkins/ref/jobs/SeedJob/workspace/dsl/

USER root
RUN chown jenkins: /usr/share/jenkins/ -R
# Eventually place here any `apt-get install` command to add tools to the image
USER jenkins

# COPY your Seed Job DSL script
COPY dsl/*.groovy /usr/share/jenkins/ref/jobs/SeedJob/workspace/dsl/