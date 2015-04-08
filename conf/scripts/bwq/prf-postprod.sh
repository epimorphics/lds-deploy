#!/bin/bash
# Process daily PRF upload after publication - will be used for routing to NRW

readonly filename="$1"

echo "Recieved PRF file: $filename"
cp "$filename" /tmp/PRF.csv
