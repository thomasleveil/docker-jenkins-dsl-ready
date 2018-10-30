#!/bin/bash

# update plugins
/opt/bin/update_jenkins_plugins.py

# start Jenkins
/sbin/tini -- /usr/local/bin/jenkins.sh "$@"