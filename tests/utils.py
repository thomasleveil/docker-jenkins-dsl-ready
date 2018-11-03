import requests
from requests.exceptions import ConnectionError, Timeout
import timeit
import time


def wait_until(check, timeout, pause, clock=timeit.default_timer):
    """Wait until a check is True."""

    ref = clock()
    now = ref
    while (now - ref) < timeout:
        if check():
            return
        time.sleep(pause)
        now = clock()

    raise Exception(
        'Timeout reached while waiting'
    )


def job_not_building(session, job):
    """
    check a jenkins job is not currently building
    """
    url = "/job/{job}/1/api/json".format(job=job)
    r = session.get(url)
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



class SessionWithUrlBase(requests.Session):
    """
    https://stackoverflow.com/a/43882437/107049
    """
    def __init__(self, url_base=None, *args, **kwargs):
        super(SessionWithUrlBase, self).__init__(*args, **kwargs)
        self.url_base = url_base

    def request(self, method, url, **kwargs):
        # Next line of code is here for example purposes only.
        # You really shouldn't just use string concatenation here,
        # take a look at urllib.parse.urljoin instead.
        modified_url = self.url_base + url

        return super(SessionWithUrlBase, self).request(method, modified_url, **kwargs)
