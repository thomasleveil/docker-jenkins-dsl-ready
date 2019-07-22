#!/bin/bash

# do not nag with Jenkins setup wizard
export JAVA_OPTS="${JAVA_OPTS} -Djenkins.install.runSetupWizard=false" 

# start Jenkins
exec /sbin/tini -- /usr/local/bin/jenkins.sh "$@"