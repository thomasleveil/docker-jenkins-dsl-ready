import pytest
from utils import is_responsive, SessionWithUrlBase

pytest_plugins = "plugins.pytest_docker"


@pytest.fixture(scope="module")
def jenkins(request, docker_services):
    """Ensure that a jenkins container is up and responsive."""

    jenkins_container_ip = docker_services.ip_for('jenkins')
    url = """http://{ip}:8080""".format(ip=jenkins_container_ip)
    docker_services.wait_until_responsive(
        timeout=600.0, pause=0.5,
        check=lambda: is_responsive(url)
    )
    session = SessionWithUrlBase(url_base=url)
    return session

