TESTS
=====

This test suite is meant to test that the produced docker image is able to start and that
Jenkins behaves as expected.

The jenkins image to test must be defined with the `IMAGE_NAME` environment variable.

tl;dr
-----

    docker build -t jenkins-dsl-ready:test .
    IMAGE_NAME=jenkins-dsl-ready:test pytest -v


Requirements
------------

In order to run the test suite, you must have the following tools on your system:

- [docker](https://www.docker.com/)
- [docker-compose](https://docs.docker.com/compose/)
- [python 3](https://www.python.org/)
- [pip](https://pypi.org/project/pip/)


Dependencies
------------

[py.test](https://docs.pytest.org) is used to run the test suite. To installed it and the 
test dependencies, run:

```
pip install -r tests/requirements.txt
```


Contributing
------------

The test suite is built with [pytest](https://docs.pytest.org/) and the help of a 
[custom pytest plugin](plugins/pytest_docker.py) which introduces the following behaviors:

- all test module files MUST have a docker-compose yaml file with the same name (but for the `.yml` extension)
- all docker compose files MUST define a service named `jenkins` _(which runs a container from the docker image to test)_
- when a test module is run, pytest uses the docker compose file to start docker containers
- when all tests from a test module are done, the containers that were created for that module are stopped
