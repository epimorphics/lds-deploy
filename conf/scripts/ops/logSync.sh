#!/bin/bash
# Backup log files for all production servers to S3

. /opt/dms/conf/scripts/config.sh

echo "[$(date -Iseconds)] Backup production apache logs to S3"
cd /var/opt/dms
FLAGS="$SSH_FLAGS -i /var/opt/dms/.ssh/lds.pem"
for server in services/*/publicationSets/production/tiers/*/servers/*
do
    if [[ $server =~ services/(.*)/publicationSets/(.*)/tiers/(.*)/servers/(.*) ]]; then
        service=${BASH_REMATCH[1]}
        tier=${BASH_REMATCH[3]}
        sname=${BASH_REMATCH[4]}
        if grep -qv Terminated $server/status ;  then
            echo "Syncing log files for $service/production/$tier/$sname"
            IP=$( jq -r .address "$server/config.json" )
            ssh -t -t $FLAGS -l ubuntu $IP sudo "aws s3 sync /var/log/apache2 s3://dms-logs/$service/production/$tier/$sname"
        fi
    fi
done
