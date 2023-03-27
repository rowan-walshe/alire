#!/bin/bash
export DOCKER_BUILDKIT=1
export $(xargs -0 -L1 -a /proc/1/environ | grep AWS_CONTAINER_CREDENTIALS_RELATIVE_URI)

# Declare images that are to be built and pushed
declare -a IMAGES=(
  "fsf-12.2.1 fsf.Dockerfile gnat_native=12.2.1 gprbuild=22.0.1 None"
  "pro-23.1 pro.Dockerfile gnat None 23.1"
  "pro-stable pro.Dockerfile stable-gnat None wave"
)

# Rebuilds all images listed in IMAGES
function build_images {
  for image in "${IMAGES[@]}"; do
    read -a args <<< "$image"
    docker build \
      -t $CI_REGISTRY/eng/devops/alire/devenv:${args[0]} \
      -f .devcontainer/base_images/${args[1]} \
      --secret id=ci_job_token,env=CI_JOB_TOKEN \
      --build-arg AWS_CONTAINER_CREDENTIALS_RELATIVE_URI=$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI \
      --build-arg DEPLOY_USERNAME=$DEPLOY_USERNAME \
      --build-arg DEPLOY_TOKEN=$DEPLOY_TOKEN \
      --build-arg GNAT=${args[2]} \
      --build-arg GPRBUILD=${args[3]} \
      --build-arg ANOD_SETUP=${args[4]} .
  done
}

# Push all images listed in IMAGES
function push_images {
  for image in "${IMAGES[@]}"; do
    read -a args <<< "$image"
    docker push $CI_REGISTRY/eng/devops/alire/devenv:${args[0]}
  done
}


docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
build_images
push_images
