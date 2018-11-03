import time
import timeit

import pytest
import requests
from requests.exceptions import ConnectionError, Timeout


def wait_until(check, timeout, pause, clock=timeit.default_timer):
    """Wait until a check is True."""
    __tracebackhide__ = True
    ref = clock()
    now = ref
    while (now - ref) < timeout:
        if check():
            return
        time.sleep(pause)
        now = clock()

    raise Timeout(
        'Timeout reached while waiting'
    )


def job_not_building(jenkins: 'JenkinsClient', job):
    """
    check a jenkins job is not currently building
    """
    url = "/job/{job}/1/api/json".format(job=job)
    r = jenkins.get(url)
    assert 200 == r.status_code, "%s. %r" % (url, r)
    return r.json()['building'] != True


def is_responsive(url):
    """Check if something responds to ``url``."""
    try:
        response = requests.get(url)
        if response.status_code == 200:
            return True
    except (ConnectionError, Timeout):
        return False


class JenkinsClient(requests.Session):
    """
    https://stackoverflow.com/a/43882437/107049
    """

    def __init__(self, url_base=None, *args, **kwargs):
        super(JenkinsClient, self).__init__(*args, **kwargs)
        self.url_base = url_base

    def request(self, method, url, **kwargs):
        # Next line of code is here for example purposes only.
        # You really shouldn't just use string concatenation here,
        # take a look at urllib.parse.urljoin instead.
        modified_url = self.url_base + url

        return super(JenkinsClient, self).request(method, modified_url, **kwargs)

    def wait_for_jenkins_to_be_ready(self):
        wait_until(timeout=600.0, pause=0.5, check=lambda: is_responsive(self.url_base))

    def assert_job_exists(self, job):
        r = self.get("/job/{job_name}/".format(job_name=job))
        assert 200 == r.status_code, r.status_code

    def start_build(self, job, timeout=60.0):
        r = self.post('/job/%s/build' % job)
        assert 201 == r.status_code, "Failed to start a build for job %s" % job
        wait_until(timeout=timeout, pause=0.5, check=lambda: self.get("/job/%s/1/" % job).status_code == 200)

    def wait_for_build_to_finish(self, job, timeout=60.0):
        wait_until(timeout=timeout, pause=0.5, check=lambda: job_not_building(self, job))

    def assert_build_exists(self, job, timeout=60.0):
        try:
            wait_until(timeout=timeout, pause=0.5, check=lambda: is_responsive("%s/job/%s/1/" % (self.url_base, job)))
        except Timeout:
            r = self.get("/job/{job_name}/1/".format(job_name=job))
            assert 200 == r.status_code, r.status_code

    def assert_build_succeeded(self, job):
        r = self.get("/job/%s/1/api/json" % job)
        assert 200 == r.status_code, r.status_code
        if r.json()['result'] == 'FAILURE':
            r = self.get("/job/%s/1/logText/progressiveText" % job)
            pytest.fail("Job %s failed : \n\n%s\n\n" % (job, r.text), pytrace=False)
        assert 'SUCCESS' == r.json()['result']


@pytest.fixture(scope="module")
def jenkins() -> JenkinsClient:
    """Ensure that a jenkins container is up and responsive."""
    __tracebackhide__ = True
    jenkins_client = JenkinsClient("http://jenkins:8080")
    jenkins_client.wait_for_jenkins_to_be_ready()
    return jenkins_client


###############################################################################
#
# Py.test hooks
#
###############################################################################

# Py.test `incremental` marker, see https://docs.pytest.org/en/latest/example/simple.html#incremental-testing-test-steps
def pytest_runtest_makereport(item, call):
    if "incremental" in item.keywords:
        if call.excinfo is not None:
            parent = item.parent
            parent._previousfailed = item


def pytest_runtest_setup(item):
    previousfailed = getattr(item.parent, "_previousfailed", None)
    if previousfailed is not None:
        pytest.xfail("previous test failed (%s)" % previousfailed.name)
