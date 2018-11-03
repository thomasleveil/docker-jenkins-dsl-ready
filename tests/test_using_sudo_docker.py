import pytest


def test_job_SeedJob_exists(jenkins):
    jenkins.assert_job_exists("SeedJob")


def test_job_SeedJob_build_created(jenkins):
    jenkins.assert_build_exists('SeedJob')


def test_job_SeedJob_succeeded(jenkins):
    jenkins.wait_for_build_to_finish('SeedJob')
    jenkins.assert_build_succeeded('SeedJob')


def test_job_test_docker_exists(jenkins):
    jenkins.assert_job_exists("test-sudo-docker")


def test_job_test_docker_build_created(jenkins):
    jenkins.start_build("test-sudo-docker")


def test_job_test_docker_suceeded(jenkins):
    jenkins.wait_for_build_to_finish("test-sudo-docker")
    jenkins.assert_build_succeeded("test-sudo-docker")
