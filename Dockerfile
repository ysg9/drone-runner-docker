ARG BASE_IMAGE
FROM $BASE_IMAGE
COPY ./drone-runner-docker /bin/drone-runner-docker
ENTRYPOINT ["/bin/drone-runner-docker"]

