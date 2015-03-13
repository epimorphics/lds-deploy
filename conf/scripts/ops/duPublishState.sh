#!/bin/bash
# Convert tier level publish to an S3 upload
# S3 area passed in as an ENV param $STATE_FOLDER

[[ $# = 1 ]] || { echo "duPublishState pubspec-json" 1>&2 ; exit 1 ; }

readonly spec="$1"

BUCKET="$STATE_FOLDER/updates/$( date +%F )/$( date '+%H-%M-%S-%N')"

touch /tmp/empty

awsAction() {
    op=$1
    file=$(echo $2 | sed -e 's/file://')
    graph=$(echo $3 | sed -e 's!/!%2F!g')
    filebase=$(basename $file | sed -e 's/_//g')
    suffix=""
    if [[ $filebase =~ (.*)(\.[^\.]+\.gz) || $filebase =~ (.*)(\.[^\.]+) ]]; then
        suffix=${BASH_REMATCH[2]}
        filebase=${BASH_REMATCH[1]}
    fi
    aws s3 cp $file "$BUCKET/${filebase}_${op}_${graph}${suffix}"
}

echo $spec | jq -r '.spec[] |
    if .op == "drop" then
        "drop file:/tmp/empty \(.graph)"
    else
        "\(.op) \(.data) \(.graph)"
    end' | while read line; do awsAction $line; done
