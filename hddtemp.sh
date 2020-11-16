#!/bin/bash

DEV=/dev/sda
HOST=nidoqueen

temp=$(sudo hddtemp -n -w $DEV)
echo "my_hddtemp,host=${HOST} temperature=${temp}"
