#!/usr/bin/python
#
# Parse files or read from stdin a list of Jenkins plugin names and output
# download URLs for the plugins and all their mandatory dependencies.
#
# USAGE:
#  
#    cat plugins.txt | resolve_jenkins_plugins_dependencies.py > plugins_url.txt
# or
#    resolve_jenkins_plugins_dependencies.py plugins1.txt plugins2.txt > plugins_url.txt
#
from __future__ import print_function

import fileinput
import json
import sys
import urllib2

URL_JENKINS_UPDATE_CENTER = 'http://updates.jenkins-ci.org/update-center.json'


def download_plugins_info():
    print("downloading %s" % URL_JENKINS_UPDATE_CENTER, file=sys.stderr)
    response = urllib2.urlopen(URL_JENKINS_UPDATE_CENTER)
    json_data = response.read().lstrip('updateCenter.post(').rstrip(');')
    return json.loads(json_data)['plugins']


def get_plugins_and_dependencies_urls(urls, plugins_data, plugin_name):
    """
    recursively get plugins and their dependencies download urls

    Parameters:
        urls - a set of url to update
        plugins_data - dict[plugin name, plugin data]
        plugin_name - the plugin to resolve the dependencies of and get the download url

    >>> urls = set()
    >>> get_plugins_and_dependencies_urls(urls, {"foo": {"url": "http://download.foo/"}}, "foo")
    >>> print(urls)  #1
    set(['http://download.foo/'])

    >>> urls = set(['http://bar'])
    >>> plugins_data = {"foo": {"url": "http://foo", "dependencies": [{"name": "foo1","optional": True}]}, "foo1": {"url": "http://foo1"}}
    >>> get_plugins_and_dependencies_urls(urls, plugins_data, "foo")
    >>> print(urls)  #2
    set(['http://bar', 'http://foo'])

    >>> urls = set()
    >>> plugins_data = {"foo": {"url": "http://foo", "dependencies": [{"name": "foo1","optional": False}]}, "foo1": {"url": "http://foo1"}}
    >>> get_plugins_and_dependencies_urls(urls, plugins_data, "foo")
    >>> print(urls)  #3
    set(['http://foo1', 'http://foo'])
    """
    if plugin_name not in plugins_data:
        print("ERROR: %r does not exists" % plugin_name, file=sys.stderr)
    else:
        this_plugin_data = plugins_data[plugin_name]
        urls.add(this_plugin_data['url'])

        if 'dependencies' in this_plugin_data:
            for dependency in this_plugin_data['dependencies']:
                if not dependency['optional']:  # only consider required dependencies
                    get_plugins_and_dependencies_urls(urls, plugins_data, dependency['name'])


def get_download_urls(plugin_data):
    urls = set()
    for plugin_name in fileinput.input():
        if plugin_name.startswith('#') \
                or plugin_name.startswith('//') \
                or plugin_name.strip() == '':
            continue
        print("resolving dependencies for %s" % plugin_name.strip(), file=sys.stderr)
        get_plugins_and_dependencies_urls(urls, plugins_data, plugin_name.strip())
    return urls


if __name__ == '__main__':
    plugins_data = download_plugins_info()
    urls = get_download_urls(plugins_data)
    print('\n'.join(urls))
