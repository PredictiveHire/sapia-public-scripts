#!/bin/bash

# Set environment variables to simulate GitHub Actions context
export SLACK_NOTIFICATION_CHANNEL_WEBHOOK_URL="https://hooks.slack.com/services/xxx"
export REPO_URL="https://github.com/PredictiveHire/xxx"
export REPO_DISPLAY_NAME="xxx"
export PR_URL="https://github.com/PredictiveHire/sapia-public-scripts/pull/8"
export PR_BASE="main"
export PR_TITLE="feat: script to notif slack channel when pr get mereged"
export PR_AUTHOR="GeekEast"
export PR_AUTHOR_URL="https://github.com/GeekEast"

# Path to your script
SCRIPT_PATH="../merge-notif.sh"

# Execute the script with simulated environment variables
chmod +x $SCRIPT_PATH
$SCRIPT_PATH \
    "$SLACK_NOTIFICATION_CHANNEL_WEBHOOK_URL" \
    "$REPO_URL" \
    "$REPO_DISPLAY_NAME" \
    "$PR_URL" \
    "$PR_BASE" \
    "$PR_TITLE" \
    "$PR_AUTHOR" \
    "$PR_AUTHOR_URL"
