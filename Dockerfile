FROM jenkins/jenkins:lts

USER root

# Install sudo to enpower jenkins (will be usefull for running docker in some cases)
RUN apt-get update \
    && apt-get install -y sudo \
		libltdl7 \
    && rm -rf /var/lib/apt/lists/* \
    && echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers

# a few helper scripts
RUN mkdir /opt/bin
COPY build/*.py build/*.sh /opt/bin/
RUN chmod +x /opt/bin/*

# Groovy script to create the "SeedJob" (the standard way, not with DSL)
COPY build/create-seed-job.groovy /usr/share/jenkins/ref/init.groovy.d/

# The place where to put the DSL files for the Seed Job to run
RUN mkdir -p /usr/share/jenkins/ref/jobs/SeedJob/workspace/

# The list of plugins to install
COPY plugins.txt /tmp/

# Download plugins and their dependencies
RUN mkdir /usr/share/jenkins/ref/plugins \
	&& ( \
	    cat /tmp/plugins.txt; \
	    unzip -l /usr/share/jenkins/jenkins.war | sed -nr 's|^.*WEB-INF/plugins/(.+?)\.hpi$|\1|p' \
	) \
	| /opt/bin/resolve_jenkins_plugins_dependencies.py \
	| /opt/bin/download_jenkins_plugins.py

# Setup Jenkins Configuration as Code - see https://github.com/jenkinsci/configuration-as-code-plugin
COPY ./JCasC ${JENKINS_HOME}/casc_configs
ENV CASC_JENKINS_CONFIG=${JENKINS_HOME}/casc_configs


# Install the docker client
COPY --from=docker:stable /usr/local/bin/docker /usr/local/bin/docker
RUN chmod +x /usr/local/bin/docker


# Docker labels
ARG BUILD_DATE
ARG VCS_REF

LABEL org.label-schema.name="Jenkins DSL ready" \
	org.label-schema.description="Jenkins ready to go for running DSL jobs" \
	org.label-schema.usage="/README.md" \
	org.label-schema.url="https://github.com/thomasleveil/docker-jenkins-dsl-ready" \
	org.label-schema.vcs-url="https://github.com/thomasleveil/docker-jenkins-dsl-ready.git" \
	org.label-schema.build-date=$BUILD_DATE \
	org.label-schema.vcs-ref=$VCS_REF \
	org.label-schema.schema-version="1.0.0-rc1"
COPY ./README.md /


###############################################################################
##                          customize below                                  ##
###############################################################################

# Eventually place here any `apt-get install` command to add tools to the image
#


# COPY your Seed Job DSL script
COPY dsl/*.groovy /usr/share/jenkins/ref/jobs/SeedJob/workspace/


###############################################################################
RUN chown jenkins: $(find /usr/share/jenkins/ref -type f -name '*.groovy')
USER jenkins
ENTRYPOINT ["/opt/bin/entrypoint.sh"]
