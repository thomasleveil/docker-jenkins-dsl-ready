import os

import pytest
from utils import JenkinsClient

pytest_plugins = "plugins.pytest_docker"


@pytest.fixture(scope="module")
def jenkins(docker_services) -> JenkinsClient:
    """Ensure that a jenkins container is up and responsive."""
    jenkins_container_ip = docker_services.ip_for('jenkins')
    jenkins_client = JenkinsClient(url_base="http://{ip}:8080".format(ip=jenkins_container_ip))
    jenkins_client.wait_for_jenkins_to_be_ready()
    return jenkins_client


###############################################################################
#
# Py.test hooks
#
###############################################################################

def pytest_report_header(config):
    return "Docker image being tested: %s" % os.environ.get('IMAGE_NAME')


# Py.test `incremental` marker, see https://docs.pytest.org/en/latest/example/simple.html#incremental-testing-test-steps
def pytest_runtest_makereport(item, call):
    if "incremental" in item.keywords:
        if call.excinfo is not None:
            parent = item.parent
            parent._previousfailed = item


def pytest_runtest_setup(item):
    previousfailed = getattr(item.parent, "_previousfailed", None)
    if previousfailed is not None:
        pytest.xfail("previous test failed (%s)" % previousfailed.name)


###############################################################################
#
# Check requirements
#
###############################################################################

if 'IMAGE_NAME' not in os.environ or os.environ['IMAGE_NAME'].strip() == '':
    pytest.exit(
        "The `IMAGE_NAME` environment variable is not set. It must be set with the name of the Jenkins Docker image to test")
