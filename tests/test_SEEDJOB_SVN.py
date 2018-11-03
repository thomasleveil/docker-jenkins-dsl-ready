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


def test_job_from_svn_exists(jenkins):
    r = jenkins.get("/job/job_from_svn/")
    assert 200 == r.status_code
