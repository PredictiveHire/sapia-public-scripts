#!/bin/bash

# fetch and source remote scripts
# TODO: update url
source <(curl https://raw.githubusercontent.com/PredictiveHire/sapia-public-scripts/main/scripts/cicd/aws/region.mappings.sh -s)

SERVICE_SHORT=false
STAGE=false
ECR_REPO_URI=false

IMAGE_TAG=false
DEPLOY_REGION=false

function usage() {
    cat <<EOM
##### Deploy Image to ECS #####
Required arguments:
    -t | --stage                The Stage: qa, sandbox, product
    -n | --service-short-name   The short name of service: e.g. org
    -u | --repo-uri             The ecr repo uri: e.g,. xxx.dkr.ecr.ap-southeast-2.amazonaws.com/phapi/org-core
Requirements: buildkite-agent, ecs-deploy script
Example: sh ./.buildkite/deploy -t qa -n org -u xxx.dkr.ecr.ap-southeast-2.amazonaws.com/phapi/org-core
EOM
    exit 3
}

function assertRequiredVariableSet() {
    if [ $SERVICE_SHORT == false ]; then
        echo "service short name is required. You can pass the value via -n | --service-short-name"
        exit 5
    fi
    if [ $STAGE == false ]; then
        echo "stage is required. You can pass the value via -t | --stage"
        exit 6
    fi
    if [ $ECR_REPO_URI == false ]; then
        echo "ecr repo uri is required. You can pass the value via -u | --repo-uri"
        exit 7
    fi
}

function deploy() {
    chmod +x ./.buildkite/ecs-deploy

    for region in $DEPLOY_REGION; do
        region_short=${zonemap[$region]}
        ecs_name=${STAGE}-${region_short}-${SERVICE_SHORT}-ecs
        echo "deploy ${ECR_REPO_URI} to ${ecs_name} with image tag ${IMAGE_TAG}"
        ./.buildkite/ecs-deploy -c ${ecs_name} -n ${ecs_name} -i ${ECR_REPO_URI} --profile infra-${STAGE} --region ${region} -e ${IMAGE_TAG}
    done
}

if [ "$BASH_SOURCE" == "$0" ]; then
    set -o errexit
    set -o pipefail
    set -u
    set -e
    # If no args are provided, display usage information
    if [ $# == 0 ]; then usage; fi

    # Loop through arguments, two at a time for key and value
    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
        -n | --service-name-short)
            SERVICE_SHORT="$2"
            shift # past argument
            ;;
        -t | --stage)
            STAGE="$2"
            shift # past argument
            ;;
        -u | --repo-uri)
            ECR_REPO_URI="$2"
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

    assertRequiredVariableSet

    IMAGE_TAG=$STAGE
    DEPLOY_REGION="$(buildkite-agent meta-data get "deploy-regions-${STAGE}")"

    deploy

    exit 0
fi