# monitoring
This repo is for monitoring scripts by telegraf and others to keep an eye on servers.
This howto and scripts assume you have a running grafana and influxDB locally or remotely on a different server.
Then, this setting will provide data to them.


# Install `telegraf` first
### Debian
Before adding Influx repository, run this so that apt will be able to read the repository.
```
sudo apt-get update && sudo apt-get install apt-transport-https
```

Add the InfluxData key
```
wget -qO- https://repos.influxdata.com/influxdb.key | sudo apt-key add -
source /etc/os-release
test $VERSION_ID = "7" && echo "deb https://repos.influxdata.com/debian wheezy stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
test $VERSION_ID = "8" && echo "deb https://repos.influxdata.com/debian jessie stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
test $VERSION_ID = "9" && echo "deb https://repos.influxdata.com/debian stretch stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
test $VERSION_ID = "10" && echo "deb https://repos.influxdata.com/debian buster stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
```

### Ubuntu
```
wget -qO- https://repos.influxdata.com/influxdb.key | sudo apt-key add -
source /etc/lsb-release
echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
```

# Enable telegraf to run at boot
According to your system setup, you have multiple choices to do this (but only one works at a time usually :))
### with systemd
```
sudo systemctl enable telegraf.service
```
### with init.d
```
sudo update-rc.d telegraf defaults
```



# telegraf.conf
Edit the provided `telegraf_client.conf` and `telegraf_server.conf` file by setting up the necessary details (and credentials) to grafana and influxDB. 
If you first want to see how many stuffs can be enabled, then check first the default `telegraf.conf` file at `/etc/telegraf/telegraf.conf`

### server
The files do not containt a heavy amount of comments like the sample files for telegraf but what you have to change for `server` is the following:

```
dc = "i4" # your datacenter id, if no datacenter, use, for instance, your department code
rack = "levi-rack" # define a rack ID here. If you monitor everything within a rack, just pick a random name
...
hostname = "banana" # this is important! This is how you can identify the monitored data coming from the server itself!
urls = ["http://127.0.0.1:8086"] # accordingly, set influxDB access properly
...
[[inputs.net]]
    interfaces = ["eth0.101", "eth0.102", "br0", "eth0"] #use your interface you want to monitor

```
Note, my server monitoring server is a BananaPI, so there is no HDD/SSD to monitor.


### client
Now, let's see the config file for the clients:
```
dc = "i4" # your datacenter id, if no datacenter, use, for instance, your department code
rack = "levi-rack" # define a rack ID here. If you monitor everything within a rack, just pick a random name
...
hostname = "server1" # this is important! This is how you can identify the monitored data coming from the server itself!
urls = ["http://192.168.1.1:8086"] # set the IP of the server
...
```
Update the rest of the telegraf configs according to your specific needs

Then, copy the config file to `/etc/telegraf/` directory.
### server
```
$ sudo cp telegraf_server.conf /etc/telegraf/telegraf.conf
```
### client
```
$ sudo cp telegraf_client.conf /etc/telegraf/telegraf.conf
```
### On both
Sometimes, `telegraf` wants to read a config file from `/etc/default/telegraf.conf`, so it is safe to create a symlink there pointing to our configuration:
```
$ sudo ln -s /etc/telegraf/telegraf.conf /etc/default/telegraf.conf
```



# Restart telegraf
### with systemd
```
sudo systemctl start telegraf
```
#### check status
```
sudo systemctl status telegraf
```

### with init.d
```
sudo service telegraf restart
```

or if you have telegraf at `/etc/init.d`, you can do the good-old way:

```
sudo /etc/init.d/telegraf restrt
```
#### check status
```
sudo service telegraf status
```

# Some features that require further tweaks
## sensor plugin
You have to install `lm-sensors`.

# HDDtemp
To enable HDDtemp, we need to install `hddtemp` and run it as daemon.
```
sudo apt-get install hddtemp
```
Edit the configuration file `/etc/default/hddtemp`, and set 
```
RUN_DAEMON="true"
```

Restart `hddtemp`
```
sudo /etc/init.d/hddtemp restart
```
### Not working?
No worries, it was not working for me either :D 
Drive is many time in sleeping mode, but even if awaken the report 30C is not reflected in grafana...it sometimes showed 3-5C :(

Let's use the script in this repo by using telegraf's `inputs.exec`.
To do, let's see how the provided `hddtemp.sh` works.
It does nothing special, but by using `sudo` and `hddtemp <DEV_ID>`, it can get the necessary data!
Then, it is parsed in a way (via `echo`) that influxDB understands.

However, user `telegraf` has to have `sudo` permission to read hddtemp. For this, we allow user `telegraf` in the sudoers file.
In particular, we allow user `telegraf` to call `hddtemp` without password, and this is the only command `telegraf` user can actually use.
Add the following line to `/etc/sudoers`
```
telegraf ALL= NOPASSWD: /usr/sbin/hddtemp
```

Now, add/uncomment the following lines in `telegraf.conf` assuming your hostname is `nidoking` and the drive you want to monitor is `/dev/sda` (set these variables according to your needs):
```
 [[inputs.exec]]
    commands = [
        "sh /home/user/monitoring/hddtemp.sh /dev/sda nidoking"
    ]
    timeout = "5s"
    data_format = "influx"

```

# WiringPI/DHT22 temperature/humidity sensor
If you have a DHT22 sensor and you can wire it to your monitoring device, e.g., to the GPIO ports of the Raspberry pi, then you 
we can use `lol_dht22` [submodule](https://github.com/technion/lol_dht22) in this repo to read those values.
In order checkout the submodule, issue the following command:
```
git submodule update --init --recursive
```

## Requirements
This submodule is based on the wiringPI C library, so first we have to install it.
Doing it on Raspberry PI is straightforward and finding materials and instruction via google is simple.
In case you want to use it in a BananaPi Pro/R1/etc. (like we do), then please refer to this [site](http://wiki.lemaker.org/BananaPro/Pi:GPIO_library) 


Then, configure and compile the library as usual:
```
./configure
make
sudo make install
```

If everything works fine, then the following command should do the job
```
sudo ./loldht 2
Raspberry Pi wiringPi DHT22 reader
www.lolware.net
Humidity = 44.60 % Temperature = 36.00 *C 
```
in case you also wired the data to the second GPIO port
