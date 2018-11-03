TESTS
=====

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