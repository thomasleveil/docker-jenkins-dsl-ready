import os

import pytest
from plugins.pytest_docker import Services, execute
from requests import Timeout
from utils import JenkinsClient

pytest_plugins = "plugins.pytest_docker"


@pytest.fixture(scope="session")
def requirements():
    if 'IMAGE_NAME' not in os.environ or os.environ['IMAGE_NAME'].strip() == '':
        pytest.exit(
            "The `IMAGE_NAME` environment variable is not set. It must be set with the name of the Jenkins Docker image to test")

    try:
        execute("docker inspect %s" % os.environ['IMAGE_NAME'])
    except:
        pytest.exit("Docker image %s does not exist in the local registry" % os.environ['IMAGE_NAME'])


@pytest.fixture(scope="module")
def jenkins(requirements, docker_services: Services) -> JenkinsClient:
    """Ensure that a jenkins container is up and responsive."""
    __tracebackhide__ = True
    jenkins_container_ip = docker_services.ip_for('jenkins')
    if not jenkins_container_ip:
        docker_services._docker_compose.execute("ps")
        docker_services._docker_compose.execute("logs --timestamps --tail=500")
        pytest.fail("Cannot find any IP address for the jenkins container", pytrace=False)

    jenkins_client = JenkinsClient(url_base="http://{ip}:8080".format(ip=jenkins_container_ip))
    try:
        jenkins_client.wait_for_jenkins_to_be_ready()
    except Timeout:
        docker_services._docker_compose.execute("ps")
        docker_services._docker_compose.execute("logs --timestamps --tail=500")
        raise
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
