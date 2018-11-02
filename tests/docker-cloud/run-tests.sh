#!/bin/bash
set -eu

cd /src

echo ">> building jenkins-dsl-ready docker image"
docker build -t tomdesinto/jenkins-dsl-ready:bats .

echo ">> running test suite"
bats tests
