ARG ALR_VERSION=1.2.2

ARG ANOD_SETUP
ARG ANOD_SANDBOX_DIR=/it/${ANOD_SETUP}
ARG GNAT=gnat

ARG AWS_CONTAINER_CREDENTIALS_RELATIVE_URI
ARG ADACORE_CD_MODE=true
ARG DEPLOY_USERNAME
ARG DEPLOY_TOKEN


FROM gitlab.adacore-it.com:5050/eng/it/gitlab-ci-images/gitlab-ci-e3:latest as download_compiler

ARG ANOD_SETUP
ARG ANOD_SANDBOX_DIR
ARG GNAT
ARG AWS_CONTAINER_CREDENTIALS_RELATIVE_URI
ARG ADACORE_CD_MODE

RUN --mount=type=secret,id=ci_job_token \
    /root/set_authentication.sh \
    && cd /it \
    && /root/set_git_config.sh \
    && if [ "${ANOD_SETUP}" = "wave" ]; then export BRANCH=wavefront; else export BRANCH=${ANOD_SETUP}; fi \
    && git clone -b $BRANCH git@ssh.gitlab.adacore-it.com:eng/it/anod.git /it/anod \
    && rm -rf ~/.gitconfig \
    && anod init --anod-dir=/it/anod ${ANOD_SETUP} ${ANOD_SANDBOX_DIR} \
    && cd ${ANOD_SANDBOX_DIR} \
    && anod install ${GNAT} \
    && anod printenv ${GNAT} >> /env \
    && find ${ANOD_SANDBOX_DIR}/x86_64-linux/${GNAT}/ -mindepth 1 -maxdepth 1 -name install -prune -o -exec rm -rf {} \;


FROM ubuntu:22.04

ARG DEPLOY_USERNAME
ARG DEPLOY_TOKEN
ARG ANOD_SETUP
ARG ANOD_SANDBOX_DIR
ARG ALR_VERSION

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
    && chmod +x /usr/local/bin/alr

COPY --from=download_compiler /it/${ANOD_SETUP} /it/${ANOD_SETUP}
COPY --from=download_compiler /env /env
