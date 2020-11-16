#!/bin/bash

DEV=/dev/sda

temp=$(sudo hddtemp -n -w $DEV)
echo "my_hddtemp,host=${HOST} temperature=${temp}"
