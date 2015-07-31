#!/bin/bash
echo "Debug script with delay ..."
for i in $(seq 1 25)
do 
    sleep 10s
    echo "Tick $i"
done
echo "... delay completed"
