#!/bin/bash

HOST='banana'

tmp_res=$(sudo loldht 2 |grep Humidity)
humidity=$(echo $tmp_res|cut -d '%' -f 1|awk '{print $3}')
temp=$(echo $tmp_res|cut -d '%' -f 2|awk '{print $3}')
echo "racktemp,host=${HOST} temperature=${temp},humidity=${humidity}"
