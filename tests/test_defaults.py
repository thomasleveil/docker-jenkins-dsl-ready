import pytest
from utils import wait_until, job_not_building

pytestmark = pytest.mark.incremental


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


@pytest.mark.parametrize("job_name", [
    'Example 1',
    'Example with docker'
])
def test_job_exists(jenkins, job_name):
    r = jenkins.get("/job/{job_name}/".format(**locals()))
    assert 200 == r.status_code
