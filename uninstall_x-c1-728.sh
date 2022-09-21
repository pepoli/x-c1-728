#!/bin/bash
#remove x728 old installtion
sudo sed -i '/ds1307/d' /etc/rc.local
sudo sed -i '/hwclock/d' /etc/rc.local
sudo sed -i '/ds1307/d' /etc/modules
sudo sed -i '/x-c1-728/d' /etc/rc.local
sudo sed -i '/x728bat/d' /etc/rc.local
sudo sed -i '/xoff/d' /home/pi/.bashrc

sudo rm /home/pi/x728*.py -rf
sudo rm /usr/local/bin/x-c1-728softsd.sh -f
sudo rm /etc/x-c1-728pwr.sh -f
#echo 'please remove old python file such x728xx.py on /home/pi/ fold'

sudo systemctl disable pigpiod
