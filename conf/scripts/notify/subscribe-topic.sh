#!/bin/bash
# Subscribe a user to a topic
#     subscribe-topic.sh  topicarn  email-address
set -o errexit
[[ $# = 2 ]] || { echo "Internal error calling subscribe-topic.sh" 1>&2 ; exit 1 ; }
. ./config.sh

readonly TOPICARN=$1
readonly ADDRESS=$2

aws sns subscribe --topic-arn $TOPICARN --protocol email  --notification-endpoint $ADDRESS | jq -r ".SubscriptionArn"
