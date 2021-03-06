import pytest

pytestmark = pytest.mark.incremental


def test_job_SeedJob_exists(jenkins):
    jenkins.assert_job_exists("SeedJob")


def test_job_SeedJob_build_created(jenkins):
    jenkins.assert_build_exists('SeedJob')


def test_job_SeedJob_succeeded(jenkins):
    jenkins.wait_for_build_to_finish('SeedJob')
    jenkins.assert_build_succeeded('SeedJob')


@pytest.mark.parametrize("job_name", [
    'Example 1',
    'Example with docker'
])
def test_jobs_exist(jenkins, job_name):
    jenkins.assert_job_exists(job_name)
