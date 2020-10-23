#!/bin/bash

DEV=/dev/sda
HOST=nidoqueen

#timestamp=$(date +%s)000000000

temp=$(sudo hddtemp -n -w $DEV)
echo "my_hddtemp,host=${HOST} temperature=${temp}"
