#!/bin/bash

DEV=/dev/sda
HOST=nidoking

#timestamp=$(date +%s)000000000

temp=$(sudo hddtemp -n -w $1)
echo "my_hddtemp,host=${2} temperature=${temp}"
