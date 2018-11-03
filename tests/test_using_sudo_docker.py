import pytest

from tests.utils import JenkinsClient

pytestmark = pytest.mark.incremental


def test_job_SeedJob_exists(jenkins: JenkinsClient):
    jenkins.assert_job_exists("SeedJob")


def test_job_SeedJob_build_created(jenkins: JenkinsClient):
    jenkins.assert_build_exists('SeedJob')


def test_job_SeedJob_succeeded(jenkins: JenkinsClient):
    jenkins.wait_for_build_to_finish('SeedJob')
    jenkins.assert_build_succeeded('SeedJob')


def test_job_test_docker_exists(jenkins: JenkinsClient):
    jenkins.assert_job_exists("test-sudo-docker")


def test_job_test_docker_build_created(jenkins: JenkinsClient):
    jenkins.start_build("test-sudo-docker")


def test_job_test_docker_suceeded(jenkins: JenkinsClient):
    jenkins.wait_for_build_to_finish("test-sudo-docker")
    jenkins.assert_build_succeeded("test-sudo-docker")
