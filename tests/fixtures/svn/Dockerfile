FROM erikxiv/subversion
COPY ./data /data
RUN cd /data \
    && svn import job_from_svn.groovy file:///var/svn/repos/job_from_svn.groovy -m 'first import'
