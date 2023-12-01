#!/bin/bash

# ! Deprecated and migrated to sapia-public-scripts repo
# you must have schema:emit in package.json

STAGE=false
SERVICE=false
SERVICE_URL_PREFIX=false
DEPLOY_REGION=false

function usage() {
    cat <<EOM
##### Publish graphql schema to apollo schema registry #####
Required arguments:
    -t | --stage                    Stage: qa, sandbox, product
    -s | --service                  Name of service. e.g. phapi-core-org
    -p | --service-url-prefix       The prefix of service url. e.g., phapi-core-org, default: --service
Requirements: pnpm, buildkite-agent
Example: sh ./.buildkite/schema.publish -t qa -s phapi-core-org -p phapi-core-org-internal
EOM

    exit 3
}

# Check requirements
function require() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "Some of the required software is not installed:"
        echo "    please install $1" >&2
        exit 4
    }
}

function assertRequiredVariablesSet() {
    if [ $STAGE == false ]; then
        echo "stage is required. You can pass the value using -t / --stage"
        exit 5
    fi
    if [ $SERVICE == false ]; then
        echo "service is required. You can pass the value using -s / --service. e.g., phapi-core-org"
        exit 6
    fi
    if [ $SERVICE_URL_PREFIX == false ]; then
        echo "service url prefix is required. You can pass the value using -p or --service-url-prefix. e.g., phapi-core-org-internal"
        exit 7
    fi
}

function generateSchema() {
    # install deps
    pnpm install --frozen-lockfile
    # emit schema
    pnpm schema:emit
}

function checkSchema() {
    # check schema in all regions
    for region in $DEPLOY_REGION; do
        GRAPH_NAME=edge-v3-graph@${STAGE}-${region}
        export APOLLO_GRAPH_REF=${GRAPH_NAME}

        echo "checking graphql schema in $STAGE-$region"
        pnpm exec rover subgraph check ${GRAPH_NAME} --name ${SERVICE} --schema schema.gql || true
    done
}

function publishSchema() {
    # publish schema to all regions
    for region in $DEPLOY_REGION; do
        GRAPH_NAME=edge-v3-graph@${STAGE}-${region}
        ROUTING_URL=https://${SERVICE_URL_PREFIX}.${region}.${STAGE}.predictivehire.com/api/${region}/graphql
        export APOLLO_GRAPH_REF=${GRAPH_NAME}

        echo "publishing graphql schema to $STAGE-$region"
        pnpm exec rover subgraph publish ${GRAPH_NAME} --name ${SERVICE} --schema ./schema.gql --routing-url ${ROUTING_URL}
    done
}

if [ "$BASH_SOURCE" == "$0" ]; then
    set -o errexit
    set -o pipefail
    set -u
    set -e
    # If no args are provided, display usage information
    if [ $# == 0 ]; then usage; fi

    require pnpm
    # require buildkite-agent

    # Loop through arguments, two at a time for key and value
    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
        -t | --stage)
            STAGE="$2"
            shift # past argument
            ;;
        -s | --service)
            SERVICE="$2"
            shift # past argument
            ;;
        -p | --service-url-prefix)
            SERVICE_URL_PREFIX="$2"
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

    assertRequiredVariablesSet

    DEPLOY_REGION="$(buildkite-agent meta-data get "publish-schema-regions-${STAGE}")"

    generateSchema
    checkSchema
    publishSchema

    exit 0
fi