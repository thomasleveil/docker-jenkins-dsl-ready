import pytest
from utils import is_responsive, SessionWithUrlBase

pytest_plugins = "plugins.pytest_docker"


@pytest.fixture(scope="module")
def jenkins(request, docker_ip, docker_services):
    """Ensure that a jenkins container is up and responsive."""

    url = """http://{ip}:{port}""".format(ip=docker_ip,
                                          port=docker_services.port_for("jenkins", 8080))
    docker_services.wait_until_responsive(
        timeout=600.0, pause=0.5,
        check=lambda: is_responsive(url)
    )
    session = SessionWithUrlBase(url_base=url)
    return session

