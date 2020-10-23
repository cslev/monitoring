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
Edit the provided `telegraf.conf` file by setting up the necessary details (and credentials) to grafana and influxDB. 
The config file is talky enough, hence I am not covering any more details about it here and now.

Then, copy it to `/etc/telegraf/telegraf.conf`.
If you first want to see how many stuffs can be enabled, then check first the default `telegraf.conf` file at `/etc/telegraf/telegraf.conf`

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
        "sh /home/lele/monitoring/hddtemp.sh /dev/sda nidoking"
    ]
    timeout = "5s"
    data_format = "influx"

```
