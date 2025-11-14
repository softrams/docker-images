FROM public.ecr.aws/lambda/python:3.12

# Install GitHub CLI
COPY --from=maniator/gh:v2.63.0 /usr/bin/gh /usr/bin/gh

# Install bash, git, and awscli
RUN dnf install -y bash git awscli && \
    dnf clean all

# Verify installations
RUN gh --version && \
    git --version && \
    python --version && \
    aws --version
