#!/bin/bash
# vairables
SLACK_NOTIFICATION_CHANNEL_WEBHOOK_URL=$1
REPO_URL=$2
REPO_DISPLAY_NAME=$3
PR_URL=$4
PR_BASE=$5
PR_TITLE=$6
PR_AUTHOR=$7
PR_AUTHOR_URL=$8

TEXT=$(cat <<EOF
🚀 Hi <!here>
Repository: <${REPO_URL}|${REPO_DISPLAY_NAME}>
Pull request: <${PR_URL}|${PR_TITLE}>
has been merged into \`${PR_BASE}\` branch by <${PR_AUTHOR_URL}|${PR_AUTHOR}>
EOF
)

# Send the notification to Slack
curl -X POST -H 'Content-type: application/json' --data "{'text':'${TEXT}'}" "${SLACK_NOTIFICATION_CHANNEL_WEBHOOK_URL}"

