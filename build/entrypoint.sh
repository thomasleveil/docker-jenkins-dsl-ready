#!/bin/bash

# update plugins
/opt/bin/update_jenkins_plugins.py

# start Jenkins
exec /sbin/tini -- /usr/local/bin/jenkins.sh "$@"