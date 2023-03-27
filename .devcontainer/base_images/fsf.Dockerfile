FROM ubuntu:22.04

ARG DEPLOY_USERNAME
ARG DEPLOY_TOKEN
ARG ALR_VERSION=1.2.2

ARG GNAT
ARG GPRBUILD

ENV ANOD_SETUP=${ANOD_SETUP}
ENV ANOD_SANDBOX_DIR=${ANOD_SANDBOX_DIR}

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
        curl \
        git \
        ca-certificates \
        unzip \
        libc6-dev \
    && rm -rf /var/lib/apt/lists/* \
    && curl -L \
        --user "${DEPLOY_USERNAME}:${DEPLOY_TOKEN}" \
        "https://gitlab.adacore-it.com/api/v4/projects/eng%2Fdevops%2Falire/packages/generic/alr/${ALR_VERSION}/alr" \
        --output /usr/local/bin/alr \
    && chmod +x /usr/local/bin/alr \
    && alr toolchain --select ${GNAT} ${GPRBUILD}
