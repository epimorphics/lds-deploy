#!/bin/bash
WaitFor() {
    local loop=1
    while [[ $loop -le 100 ]]
    do
        echo "Hello $loop"
        echo "Hello $loop" >> /tmp/messages
        sleep 1
        loop=$(( $loop + 1 ))
    done
}

WaitFor
echo "Exiting"
