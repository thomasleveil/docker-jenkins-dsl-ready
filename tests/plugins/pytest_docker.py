# -*- coding: utf-8 -*-
import json
import os
import re
import subprocess
import time
import timeit

import attr
import pytest


def execute(command, success_codes=(0,)):
    """Run a shell command."""
    try:
        output = subprocess.check_output(
            command, stderr=subprocess.STDOUT, shell=True,
        )
        status = 0
    except subprocess.CalledProcessError as error:
        output = error.output or b''
        status = error.returncode
        command = error.cmd
    output = output.decode('utf-8')
    if status not in success_codes:
        raise Exception(
            'Command %r returned %d: """%s""".' % (command, status, output)
        )
    return output


@attr.s(frozen=True)
class Services(object):
    """."""
    _docker = attr.ib()
    _docker_compose = attr.ib()
    _services = attr.ib(init=False, default=attr.Factory(dict))

    def container_id(self, service):
        """Get the container id of the first container for a service"""

        # Lookup in the cache.
        cache = self._services.get(service, {}).get('_id', None)
        if cache is not None:
            return cache

        output = self._docker_compose.execute(
            'ps -q %s' % (service,)
        ).strip()
        match = re.match(r"""^(?P<id>[0-9a-f]+)$""", output)

        if not match:
            raise ValueError(
                'Could not detect id for "%s".' % (service,)
            )

        id = match.group('id')

        # Store it in cache in case we request it multiple times.
        self._services.setdefault(service, {})['_id'] = id

        return id

    def ip_for(self, service):
        """Get the effective ip for a service first containerr."""

        # Lookup in the cache.
        cache = self._services.get(service, {}).get('_ip', None)
        if cache is not None:
            return cache

        container_id = self.container_id(service)

        output = self._docker.execute(
            'inspect %s' % (container_id,)
        ).strip()
        data = json.loads(output)
        if not data:
            raise ValueError(
                'Could not detect ip for "%s".' % (service,)
            )

        net_info = data[0]["NetworkSettings"]["Networks"]
        if "bridge" in net_info:
            ip_address = net_info["bridge"]["IPAddress"]
        else:
            # not default bridge network, fallback on first network defined
            network_name = list(net_info.keys())[0]
            ip_address = net_info[network_name]["IPAddress"]

        # Store it in cache in case we request it multiple times.
        self._services.setdefault(service, {})['_ip'] = ip_address

        return ip_address

    @staticmethod
    def wait_until_responsive(check, timeout, pause,
                              clock=timeit.default_timer):
        """Wait until a service is responsive."""

        ref = clock()
        now = ref
        while (now - ref) < timeout:
            if check():
                return
            time.sleep(pause)
            now = clock()

        raise Exception(
            'Timeout reached while waiting on service!'
        )


def str_to_list(arg):
    if isinstance(arg, (list, tuple)):
        return arg
    return [arg]


@attr.s(frozen=True)
class DockerComposeExecutor(object):
    _compose_files = attr.ib(convert=str_to_list)
    _compose_project_name = attr.ib()

    def execute(self, subcommand):
        command = "docker-compose"
        for compose_file in self._compose_files:
            command += ' -f "{}"'.format(compose_file)
        command += ' -p "{}" {}'.format(self._compose_project_name, subcommand)
        return execute(command)


@attr.s(frozen=True)
class DockerExecutor(object):

    def execute(self, subcommand):
        command = "docker {}".format(subcommand)
        return execute(command)


@pytest.fixture(scope='module')
def docker_compose_file(request, pytestconfig):
    """Get the docker-compose.yml absolute path.

    Override this fixture in your tests if you need a custom location.

    """
    test_module_dir = os.path.dirname(request.module.__file__)
    return os.path.join(test_module_dir, request.module.__name__ + '.yml')


@pytest.fixture(scope='module')
def docker_compose_project_name():
    """ Generate a project name using the current process' PID.

    Override this fixture in your tests if you need a particular project name.
    """
    return "pytest{}".format(os.getpid())


@pytest.fixture(scope='module')
def docker_services(
        docker_compose_file, docker_compose_project_name
):
    """Ensure all Docker-based services are up and running."""
    docker = DockerExecutor()
    docker_compose = DockerComposeExecutor(
        docker_compose_file, docker_compose_project_name
    )

    # Spawn containers.
    docker_compose.execute('up --build -d')

    # Let test(s) run.
    yield Services(docker, docker_compose)

    # Clean up.
    docker_compose.execute('down -v')


__all__ = (
    'docker_compose_file',
    'docker_services',
)
