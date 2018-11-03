import pytest
from utils import wait_until, job_not_building


def test_job_SeedJob_exists(jenkins):
    r = jenkins.get("/job/SeedJob/")
    assert 200 == r.status_code


def test_job_SeedJob_build_created(jenkins):
    r = jenkins.get("/job/SeedJob/1/")
    assert 200 == r.status_code


def test_job_SeedJob_suceeded(jenkins):
    wait_until(timeout=60.0, pause=0.5,
               check=lambda: job_not_building(jenkins, "SeedJob"))

    r = jenkins.get("/job/SeedJob/1/api/json")
    assert 200 == r.status_code
    assert 'SUCCESS' == r.json()['result']


def test_job_test_sudo_docker_exists(jenkins):
    r = jenkins.get("/job/test-sudo-docker/")
    assert 200 == r.status_code


def test_job_test_sudo_docker_build_created(jenkins):
    r = jenkins.post('/job/test-sudo-docker/build')
    assert 201 == r.status_code, "Failed to start a build"
    wait_until(timeout=60.0, pause=0.5,
               check=lambda: jenkins.get("/job/test-sudo-docker/1/").status_code == 200)


def test_job_test_docker_suceeded(jenkins):
    wait_until(timeout=60.0, pause=0.5,
               check=lambda: job_not_building(jenkins, "test-sudo-docker"))

    r = jenkins.get("/job/test-sudo-docker/1/api/json")
    assert 200 == r.status_code
    assert 'SUCCESS' == r.json()['result']
