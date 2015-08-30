#!/usr/bin/python -u
#
# Download urls and save files in the reference directory.
#
# USAGE:
#  
#    cat list_of_url.txt | download_jenkins_plugins.py
# or 
#    download_jenkins_plugins.py list_of_url1.txt list_of_url2.txt
#
import fileinput
from multiprocessing import Pool
import os
import urllib2


DESTINATION_FOLDER = '/usr/share/jenkins/ref/plugins'
DOWNLOAD_POOL_SIZE = 10


def process_url(url):
    if not url:
        return
    file_name = url.split('/')[-1]
    print('downloading {:<30} \t{}'.format(file_name, url))
    response = urllib2.urlopen(url)
    with open(os.path.join(DESTINATION_FOLDER, file_name), 'wb') as f:
        f.write(response.read())


if __name__ == '__main__':
    if not os.path.isdir(DESTINATION_FOLDER):
        os.makedirs(DESTINATION_FOLDER)
        
    list_of_urls = set(map(lambda x: x.strip(), fileinput.input()))
    pool = Pool(DOWNLOAD_POOL_SIZE)
    pool.map(process_url, list_of_urls)