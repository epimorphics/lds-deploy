#!/bin/bash
# Build a TDB images of the most recent dump of a S3-based service
# The base folder should be the top level folder not including "images"/"updates" and no final "/"
# Usage: buildLatestImage s3folder

set -o errexit

[[ $# = 1 ]] || { echo "Usage: buildLatestImage s3folder" 1>&2 ; exit 1 ; }
s3folder="$1"

. config.sh
. automation_lib.sh

# Find the dump to be loaded
dump=$( findLastDump "$s3folder" )
[[ -n $dump ]] || { echo "Could not find S3 dump" 1>&2 ; exit 1 ; }
image=$( echo "$dump" | sed -e 's/dump.nq.gz/image.tgz/' )

if [[ -n $(aws s3 ls "$image") ]]; then
    echo "Image already exists, not updating"
    exit 0
fi

# Create a working area
buildir="$DEFAULT_WORK_DIR/makeImage-$( date +%F%T%N )$RANDOM"
mkdir -p $buildir
cd $buildir

# Fetch the dump
echo "Fetch dump: $dump"
aws s3 cp "$dump" dump.nq.gz ||  { echo "Failed to download dump $dump" 1>&2 ; exit 1 ; }

# Build the image
export SORT_ARGS="--buffer-size=50% --parallel=3 --temporary-directory=/tmp/dms-work"
/opt/jena/bin/tdbloader2 --loc DS-DB dump.nq.gz ||  { echo "Failed to build image" 1>&2 ; exit 1 ; }
tar czf DS-DB.tgz DS-DB ||  { echo "Failed to package image" 1>&2 ; exit 1 ; }

# Check contains expected data
readingsCount=$( /opt/jena/bin/tdbquery --results CSV --set tdb:unionDefaultGraph=true --loc=DS-DB "PREFIX rt:  <http://environment.data.gov.uk/flood-monitoring/def/core/> SELECT * WHERE {[] rt:latestReading ?id }" | wc -l )
[[ $readingsCount > 1000 ]] || { echo "Only found $readingsCount readings, aborting"; exit 1; }

# Upload the image
echo "Uploading built image to: $image"
aws s3 cp DS-DB.tgz "$image"  ||  { echo "Failed to upload image" 1>&2 ; exit 1 ; }

# Check it is there and non-zero
(( $(aws s3 ls "$image"  | awk '{print $3}') > 0 )) ||  { echo "Image didn't arrive" 1>&2 ; exit 1 ; }

cd /tmp
rm -r $buildir
