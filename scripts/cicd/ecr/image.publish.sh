#!/bin/bash

CONTAINER_NAME=false
RELEASE_TAG_INDEX=false
ECR_REPO_URI=false

function usage() {
    cat <<EOM
##### Publish images to ECR #####
Required arguments:
    -n | --container-name      The container name. e.g., phapi-core-org
    -u | --repo-uri            The uri of ecr repo
    -i | --tag-index           The unique number used for release tag
Requirements: docker
Example: sh ./.buildkite/docker.publish -n phapi-core-org -i "\${BUILDKITE_BUILD_NUMBER}" -u xxxx.dkr.ecr.ap-southeast-2.amazonaws.com/phapi/org-core
EOM
    exit 3
}

function require() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "Some of the required software is not installed:"
        echo "    please install $1" >&2
        exit 4
    }
}

# Check that all required variables/combinations are set
function assertRequiredVariablesSet() {
    if [ $CONTAINER_NAME == false ]; then
        echo "container name is required. You can pass the value via -n | --container-name"
        exit 5
    fi
    if [ $RELEASE_TAG_INDEX == false ]; then
        echo "tag index is required. You can pass the value via -i | --tag-index"
        exit 6
    fi
    if [ $ECR_REPO_URI == false ]; then
        echo "ecr repo uri is required. You can pass the value via -u | --repo-uri"
        exit 7
    fi
}

function publishDockerImage() {
    DOCKER_RELEASE_TAG="v1.0.$RELEASE_TAG_INDEX"

    echo "- build local image: $CONTAINER_NAME:$DOCKER_RELEASE_TAG"
    docker build -t "$CONTAINER_NAME:$DOCKER_RELEASE_TAG" .

    echo "- tag image from local: $CONTAINER_NAME:$DOCKER_RELEASE_TAG" to remote: "$ECR_REPO_URI:$DOCKER_RELEASE_TAG"
    docker tag "$CONTAINER_NAME:$DOCKER_RELEASE_TAG" "$ECR_REPO_URI:$DOCKER_RELEASE_TAG"

    echo "- push image to remote"
    docker push "$ECR_REPO_URI:$DOCKER_RELEASE_TAG"
}

if [ "$BASH_SOURCE" == "$0" ]; then
    set -o errexit
    set -o pipefail
    set -u
    set -e

    # If no args are provided, display usage information
    if [ $# == 0 ]; then usage; fi

    require docker

    # Loop through arguments, two at a time for key and value
    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
        -u | --repo-uri)
            ECR_REPO_URI="$2"
            shift # past argument
            ;;
        -n | --container-name)
            CONTAINER_NAME="$2"
            shift # past argument
            ;;
        -i | --tag-index)
            RELEASE_TAG_INDEX="$2"
            shift # past argument
            ;;
        *)
            #If another key was given that is not empty display usage.
            if [[ ! -z "$key" ]]; then
                usage
                exit 2
            fi
            ;;
        esac
        shift # past argument or value
    done

    # Check that required arguments are provided
    assertRequiredVariablesSet
    publishDockerImage
fi