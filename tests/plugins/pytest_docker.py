# -*- coding: utf-8 -*-
import json
import os
import re
import subprocess

import attr
import pytest


def execute(command, success_codes=(0,), no_print=False):
    """Run a shell command."""
    no_print or print("> %s" % command)
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
    no_print or print(output)
    if status not in success_codes:
        raise Exception(
            'Command %r returned %d: """%s""".' % (command, status, output)
        )
    return output


@attr.s(frozen=True)
class Services(object):
    """."""
    _docker = attr.ib()  # type: DockerExecutor
    _docker_compose = attr.ib()  # type: DockerComposeExecutor
    _services = attr.ib(init=False, default=attr.Factory(dict))

    def container_id(self, service):
        """Get the container id of the first container for a service"""

        # Lookup in the cache.
        cache = self._services.get(service, {}).get('_id', None)
        if cache is not None:
            return cache

        output = self._docker_compose.execute(
            'ps -q %s' % (service,), no_print=True
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

    def inspect_container(self, container_id):
        output = self._docker.execute(
            'inspect %s' % (container_id,), no_print=True
        ).strip()
        data = json.loads(output)
        if not data:
            raise ValueError(
                'Could not inspect container %s' % (container_id,)
            )
        return data

    def inspect_service(self, service):
        container_id = self.container_id(service)
        data = self.inspect_container(container_id)
        return data

    def ip_for(self, service):
        """Get the effective ip for a service first containerr."""

        # Lookup in the cache.
        cache = self._services.get(service, {}).get('_ip', None)
        if cache is not None:
            return cache

        data = self.inspect_service(service)
        net_info = data[0]["NetworkSettings"]["Networks"]
        if "bridge" in net_info:
            ip_address = net_info["bridge"]["IPAddress"]
        else:
            # not default bridge network, fallback on first network defined
            network_name = list(net_info.keys())[0]
            ip_address = net_info[network_name]["IPAddress"]

        if ip_address:
            # Store it in cache in case we request it multiple times.
            self._services.setdefault(service, {})['_ip'] = ip_address

        return ip_address


def str_to_list(arg):
    if isinstance(arg, (list, tuple)):
        return arg
    return [arg]


@attr.s(frozen=True)
class DockerComposeExecutor(object):
    _compose_dir = attr.ib()
    _compose_files = attr.ib(convert=str_to_list)
    _compose_project_name = attr.ib()

    def execute(self, subcommand, no_print=False):
        command = "docker-compose"
        for compose_file in self._compose_files:
            command += ' -f "{}"'.format(compose_file)
        command += ' --project-directory "{}" --project-name "{}" {}'.format(self._compose_dir,
                                                                             self._compose_project_name, subcommand)
        return execute(command, no_print=no_print)


@attr.s(frozen=True)
class DockerExecutor(object):

    def execute(self, subcommand, no_print=False):
        command = "docker {}".format(subcommand)
        return execute(command, no_print=no_print)


@pytest.fixture(scope='module')
def docker_compose_file(request):
    """Get the docker-compose.yml absolute path.

    Override this fixture in your tests if you need a custom location.

    """
    test_module_dir = os.path.dirname(request.module.__file__)
    return os.path.join(test_module_dir, request.module.__name__ + '.yml')


@pytest.fixture(scope='module')
def docker_compose_project_name(request):
    """ Generate a project name using the current test module's name.

    Override this fixture in your tests if you need a particular project name.
    """
    return request.module.__name__


@pytest.fixture(scope='module')
def docker_services(
        request, docker_compose_file, docker_compose_project_name
) -> Services:
    """Ensure all Docker-based services are up and running."""
    test_module_dir = os.path.dirname(request.module.__file__)

    docker = DockerExecutor()
    docker_compose = DockerComposeExecutor(
        test_module_dir, docker_compose_file, docker_compose_project_name
    )

    # Spawn containers.
    docker_compose.execute('up --build --force-recreate -d')

    # Let test(s) run.
    yield Services(docker, docker_compose)

    # Clean up.
    docker_compose.execute('stop')


__all__ = (
    'docker_compose_file',
    'docker_services',
)
