TESTS
=====

This test suite is meant to test that the produced docker image is able to start and that
Jenkins behaves as expected.

The jenkins image to test must be defined with the `IMAGE_NAME` environment variable.

tl;dr
-----

    docker build -t jenkins-dsl-ready:test .
    IMAGE_NAME=jenkins-dsl-ready:test tests/run_tests.sh


Requirements
------------

In order to run the test suite, you must have the following tools on your system:

- [docker](https://www.docker.com/)
- [docker-compose](https://docs.docker.com/compose/)


Contributing
------------

The test suite is built with [pytest](https://docs.pytest.org/) and provides a 
[jenkins pytest fixture](conftest.py) which helps asserting Jenkins stuff.

Rules:

- all test module files MUST have a docker-compose yaml file with the same name (but for the `.yml` extension)
- all docker compose files MUST define a service named `jenkins` _(which runs a container from the docker image to test)_
- all docker compose files MUST define a service named `sut` depending on the `jenkins` service defined as followed:

```yaml
  sut:
    build:
      context: lib
      dockerfile: Dockerfile-test-runner
    depends_on:
      - jenkins
    volumes:
      - ./:/src
    command: test_xxxxxxx.py
```

where `test_xxxxxxx.py` is named after the name of the docker compose file.