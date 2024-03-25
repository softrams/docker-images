FROM ghcr.io/softrams/docker-images:tfswitch-latest
RUN useradd -ms /bin/bash -u 1000 terraform-ci

USER terraform-ci
ENV PATH="${PATH}:/home/terraform-ci/bin"
ENTRYPOINT ["/bin/bash"]
