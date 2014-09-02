#!/bin/bash
# Generate synthetic data to simulate e.g. an ftp fetch 

readonly file=$1

echo "label,description" > $file
echo "entry 1,I am first" >> $file
echo "entry 2,I am second" >> $file
echo "entry 3,I am last" >> $file
