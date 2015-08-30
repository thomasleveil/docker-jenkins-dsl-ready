FROM jenkins

USER root

# Install docker, so docker commands can be used in jobs
RUN curl -sSL https://get.docker.com/ubuntu | sh \
    && rm -rf /var/lib/apt/lists/* 

# Install sudo to enpower jenkins (will be usefull for running docker in some cases)
RUN apt-get update \
    && apt-get install -y sudo \
    && rm -rf /var/lib/apt/lists/* \
    && echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers

# a few helper scripts
RUN mkdir /opt/bin
COPY build/*.py build/*.sh /opt/bin/
RUN chmod +x /opt/bin/*

# Groovy script to create the "SeedJob" (the standard way, not with DSL)
COPY build/create-seed-job.groovy /usr/share/jenkins/ref/init.groovy.d/

# The place where to put the DSL files for the Seed Job to run
RUN mkdir -p /usr/share/jenkins/ref/jobs/SeedJob/workspace/dsl/

# The list of plugins to install
COPY plugins.txt /tmp/

# Download plugins and their dependencies
RUN mkdir /usr/share/jenkins/ref/plugins \
	&& ( \
	    cat /tmp/plugins.txt; \
	    unzip -l /usr/share/jenkins/jenkins.war | sed -nr 's|^.*WEB-INF/plugins/(.+?)\.hpi$|\1|p' \
	) \
	| /opt/bin/resolve_jenkins_plugins_dependencies.py \
	| /opt/bin/dowload_jenkins_plugins.py

###############################################################################
##                          customize below                                  ##
###############################################################################

# Eventually place here any `apt-get install` command to add tools to the image
#


# COPY your Seed Job DSL script
COPY dsl/*.groovy /usr/share/jenkins/ref/jobs/SeedJob/workspace/


###############################################################################
RUN chown jenkins: /usr/share/jenkins/ -R
USER jenkins
ENTRYPOINT ["/opt/bin/entrypoint.sh"]