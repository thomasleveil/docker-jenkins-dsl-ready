FROM alpine/git:1.0.4
RUN apk --no-cache add git-daemon
COPY ./data /data

WORKDIR /data
RUN git init . \
    && git config --global user.email 'you@example.com' \
    && git config --global user.name 'Your Name' \
    && git add job_from_git.groovy \
    && git commit -m 'first import'


EXPOSE 9418
CMD ["daemon", "--export-all", "--enable=receive-pack"]
