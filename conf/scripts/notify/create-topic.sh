#!/bin/bash
# Create a topic via which messages can be send to a user/group
#     create-topic.sh  topicname
# Returns the the unique id (arn) of the topic as a line on stdout
set -o errexit
[[ $# = 1 ]] || { echo "Internal error calling create-topic.sh" 1>&2 ; exit 1 ; }
. ./config.sh

readonly TOPICNAME=$1

arn=$( aws sns create-topic --name "$TOPICNAME" | jq -r ".TopicArn" )
aws sns set-topic-attributes --topic-arn $arn --attribute-name DisplayName --attribute-value "DMS notification: $TOPICNAME"
echo $arn
