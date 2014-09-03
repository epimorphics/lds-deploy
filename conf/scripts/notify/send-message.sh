#!/bin/bash
# Send a message to a topic
#     send-message topic  message
set -o errexit
[[ $# = 2 ]] || { echo "Internal error calling send-message.sh" 1>&2 ; exit 1 ; }
. ./config.sh

readonly TOPIC_ARN=$1
readonly MESSAGE=$2

aws sns publish --topic-arn $TOPIC_ARN --subject "DMS notification" --message "$2" > /dev/null
