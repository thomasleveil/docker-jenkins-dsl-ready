#!/usr/bin/python
#
# Copy plugins from /usr/share/jenkins/ref/plugins/ to $JENKINS_HOME/plugins/ if the destination
# file is missing or if the plugin in the reference directory is more recent.
#
# USAGE:
#  
#    update_plugins.py
#
from __future__ import print_function
import glob
import os
import sys
import re
import zipfile
from distutils.version import LooseVersion
import shutil

REFERENCE_FOLDER = '/usr/share/jenkins/ref/plugins'
DESTINATION_FOLDER = os.path.join(os.environ['JENKINS_HOME'], 'plugins')

re_plugin_version = re.compile("(?ms).*Plugin-Version: ([\d.]+).*")


def error(*objs):
    print("ERROR: ", *objs, file=sys.stderr)


def get_plugin_version(hpi_filename):
    """
    Extract the plugin version from the MANIFEST.MF

    :param hpi_filename: string hpi file name
    :return: distutils.version.StrictVersion
    """
    with zipfile.ZipFile(hpi_filename) as z:
        return LooseVersion(re_plugin_version.sub(r"\1", z.read('META-INF/MANIFEST.MF')))


def touch(file_name):
    with open(file_name, 'a'):
        pass


if __name__ == '__main__':
    if not os.path.isdir(REFERENCE_FOLDER):
        error("%r does not exists" % REFERENCE_FOLDER)
        sys.exit(1)

    if not os.path.isdir(DESTINATION_FOLDER):
        os.makedirs(DESTINATION_FOLDER)

    for reference_file in glob.glob(os.path.join(REFERENCE_FOLDER, '*.hpi')):
        plugin_basename = os.path.basename(reference_file)
        destination_file = os.path.join(DESTINATION_FOLDER, plugin_basename)
        reference_plugin_version = get_plugin_version(reference_file)

        jpi_file = os.path.join(DESTINATION_FOLDER, os.path.splitext(plugin_basename)[0] + '.jpi')
        pinned_file = jpi_file + ".pinned"
        if not os.path.isfile(destination_file):
            if os.path.isfile(jpi_file):
                destination_file = jpi_file

        if os.path.isfile(destination_file):
            current_plugin_version = get_plugin_version(destination_file)
            if reference_plugin_version > current_plugin_version:
                print("upgrading plugin %s (%s -> %s)" %
                      (plugin_basename, current_plugin_version, reference_plugin_version))
                shutil.copy(reference_file, destination_file)
                touch(pinned_file)
            else:
                print("plugin %s is already up to date (%s)" % (plugin_basename, current_plugin_version))
        else:
            print("copying plugin %s (%s) %s" % (plugin_basename, reference_plugin_version, destination_file))
            shutil.copy(reference_file, destination_file)
            touch(pinned_file)
