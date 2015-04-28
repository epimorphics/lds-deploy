#!/bin/bash
# Check PRF publication file for welsh and if so re-route to NRW
readonly filename=$1

if grep -qi prediction_text_cy $filename ; then
    echo "Publishing $filename to NRW"
    curl -i -u $(cat /var/opt/dms/.credentials/nrw.forecasts) -H "Content-Type: text/csv" -X POST --data-binary "@$1" https://nrw-controller.epimorphics.net/dms/api/nrwbwq/components/forecasts/publishProduction
    # Force failure exit to prevent publication in EA
    exit 1;
else
    echo "Publishing in EA service"
fi
