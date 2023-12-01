#!/bin/bash

STAGE=false
ECR_REPOSITORY_NAME=false
RELEASE_TAG_INDEX=false

DOCKER_STAGE_RELEASE_TAG=false
DOCKER_RELEASE_TAG=false

function usage() {
    cat <<EOM
##### Publish images to ECR with stage tag #####
Required arguments:
    -s | --stage               The stage: qa, sandbox, product
    -n | --ecr-repo-name       The name of ecr repo. e.g., phapi/org-core
    -i | --tag-index           The unique number used for release tag
Requirements: aws, jq
Example: sh ./.buildkite/docker-stage.publish -s qa -n phapi/org-core -i "\${BUILDKITE_BUILD_NUMBER}"
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
    if [ $RELEASE_TAG_INDEX == false ]; then
        echo "release tag index is required. You can pass the by -i | --tag-index"
        exit 5
    fi
    if [ $STAGE == false ]; then
        echo "stage is required. You can pass the value by -s | --stage."
        exit 6
    fi
    if [ $ECR_REPOSITORY_NAME == false ]; then
        echo "ecr repo name is required. You can pass the value by -n | --ecr-repo-name"
        exit 7
    fi
}

function publishDockerImage() {
    TAGS=$(aws ecr describe-images --repository-name "$ECR_REPOSITORY_NAME" --image-ids imageTag="$DOCKER_RELEASE_TAG" --profile infra-qa --region ap-southeast-2 | jq --raw-output '.imageDetails[0].imageTags')

    if echo "$TAGS" | grep -q "$DOCKER_STAGE_RELEASE_TAG"; then
        echo "already taged with $DOCKER_STAGE_RELEASE_TAG"
    else
        echo "tag with $DOCKER_STAGE_RELEASE_TAG"
        MANIFEST=$(aws ecr batch-get-image --repository-name "$ECR_REPOSITORY_NAME" --image-ids imageTag="$DOCKER_RELEASE_TAG" --output json --profile infra-qa --region ap-southeast-2 | jq --raw-output '.images[0].imageManifest')
        aws ecr put-image --repository-name "$ECR_REPOSITORY_NAME" --profile infra-qa --region ap-southeast-2 --image-tag "$DOCKER_STAGE_RELEASE_TAG" --image-manifest "$MANIFEST"
    fi
}

if [ "$BASH_SOURCE" == "$0" ]; then
    set -o errexit
    set -o pipefail
    set -u
    set -e

    # If no args are provided, display usage information
    if [ $# == 0 ]; then usage; fi

    require aws
    require jq

    # Loop through arguments, two at a time for key and value
    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
        -s | --stage)
            STAGE="$2"
            shift # past argument
            ;;
        -n | --ecr-repo-name)
            ECR_REPOSITORY_NAME="$2"
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

    DOCKER_STAGE_RELEASE_TAG="$STAGE"
    DOCKER_RELEASE_TAG="v1.0.$RELEASE_TAG_INDEX"
    
    publishDockerImage
fi