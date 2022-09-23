#X728 RTC setting up
sudo sed -i '$ i rtc-ds1307' /etc/modules
sudo sed -i '$ i echo ds1307 0x68 > /sys/class/i2c-adapter/i2c-1/new_device' /etc/rc.local
sudo sed -i '$ i hwclock -s' /etc/rc.local
sudo sed -i '$ i #x-c1-728 Start power management on boot' /etc/rc.local

#x728 Powering on /reboot /full shutdown through hardware
#!/bin/bash

#sudo sed -e '/shutdown/ s/^#*/#/' -i /etc/rc.local

echo '#!/bin/bash

SHUTDOWN_728=5
SHUTDOWN_c1=4
REBOOTPULSEMINIMUM=200
REBOOTPULSEMAXIMUM=600
echo "$SHUTDOWN_728" > /sys/class/gpio/export
echo "in" > /sys/class/gpio/gpio$SHUTDOWN_728/direction
echo "$SHUTDOWN_c1" > /sys/class/gpio/export
echo "in" > /sys/class/gpio/gpio$SHUTDOWN_c1/direction
BOOT_728=12
BOOT_c1=17
echo "$BOOT_728" > /sys/class/gpio/export
echo "out" > /sys/class/gpio/gpio$BOOT_728/direction
echo "1" > /sys/class/gpio/gpio$BOOT_728/value
echo "$BOOT_c1" > /sys/class/gpio/export
echo "out" > /sys/class/gpio/gpio$BOOT_c1/direction
echo "1" > /sys/class/gpio/gpio$BOOT_c1/value


#echo "X728 Shutting down..."

while [ 1 ]; do
  SHUTDOWN_728Signal=$(cat /sys/class/gpio/gpio$SHUTDOWN_728/value)
  SHUTDOWN_c1Signal=$(cat /sys/class/gpio/gpio$SHUTDOWN_c1/value)
  if [ $SHUTDOWN_728Signal = 0 ] && [ $SHUTDOWN_c1Signal = 0 ]; then
    /bin/sleep 0.2
  else
    pulseStart=$(date +%s%N | cut -b1-13)
    while [ $SHUTDOWN_728Signal = 1 ] || [ $SHUTDOWN_c1Signal = 1 ]; do
      /bin/sleep 0.02
      if [ $(($(date +%s%N | cut -b1-13)-$pulseStart)) -gt $REBOOTPULSEMAXIMUM ]; then
        echo "X728 Shutting down", SHUTDOWN, ", halting Rpi ..."
        sudo poweroff
        exit
      fi
      SHUTDOWN_728Signal=$(cat /sys/class/gpio/gpio$SHUTDOWN_728/value)
      SHUTDOWN_c1Signal=$(cat /sys/class/gpio/gpio$SHUTDOWN_c1/value)
    done
    if [ $(($(date +%s%N | cut -b1-13)-$pulseStart)) -gt $REBOOTPULSEMINIMUM ]; then
      echo "X728 Rebooting", SHUTDOWN, ", recycling Rpi ..."
      sudo reboot
      exit
    fi
  fi
done' > /etc/x-c1-728pwr.sh
sudo chmod +x /etc/x-c1-728pwr.sh
sudo sed -i '$ i /etc/x-c1-728pwr.sh &' /etc/rc.local


#X728 full shutdown through Software
#!/bin/bash

sudo sed -e '/button/ s/^#*/#/' -i /etc/rc.local

echo '#!/bin/bash

BUTTON_728=13
BUTTON_c1=27
echo "$BUTTON_728" > /sys/class/gpio/export;
echo "out" > /sys/class/gpio/gpio$BUTTON_728/direction
echo "1" > /sys/class/gpio/gpio$BUTTON_728/value
echo "$BUTTON_c1" > /sys/class/gpio/export;
echo "out" > /sys/class/gpio/gpio$BUTTON_c1/direction
echo "1" > /sys/class/gpio/gpio$BUTTON_c1/value

SLEEP=${1:-4}

re='^[0-9\.]+$'
if ! [[ $SLEEP =~ $re ]] ; then
   echo "error: sleep time not a number" >&2; exit 1
fi

echo "X728 Shutting down..."
/bin/sleep $SLEEP

echo "0" > /sys/class/gpio/gpio$BUTTON_728/value
echo "0" > /sys/class/gpio/gpio$BUTTON_c1/value
' > /usr/local/bin/x-c1-728softsd.sh
sudo chmod +x /usr/local/bin/x-c1-728softsd.sh
sudo echo "alias xoff='sudo /usr/local/bin/x-c1-728softsd.sh'" >> /home/pi/.bashrc

#X728 Battery voltage & precentage reading
#!/bin/bash

#Get current PYTHON verson, 2 or 3
#PY_VERSION=`python3 -V 2>&1|awk '{print $2}'|awk -F '.' '{print $1}'`

#sudo sed -e '/shutdown/ s/^#*/#/' -i /etc/rc.local

echo '#!/usr/bin/env python
import struct
import smbus
import sys
import time
import RPi.GPIO as GPIO

# Global settings
# GPIO is 26 for x728 v2.0, GPIO is 13 for X728 v1.2/v1.3
GPIO_PORT 	= 13
I2C_ADDR    = 0x36

GPIO.setmode(GPIO.BCM)
GPIO.setup(GPIO_PORT, GPIO.OUT)
GPIO.setwarnings(False)

def readVoltage(bus):

     address = I2C_ADDR
     read = bus.read_word_data(address, 2)
     swapped = struct.unpack("<H", struct.pack(">H", read))[0]
     voltage = swapped * 1.25 /1000/16
     return voltage

def readCapacity(bus):

     address = I2C_ADDR
     read = bus.read_word_data(address, 4)
     swapped = struct.unpack("<H", struct.pack(">H", read))[0]
     capacity = swapped/256
     return capacity

bus = smbus.SMBus(1) # 0 = /dev/i2c-0 (port I2C0), 1 = /dev/i2c-1 (port I2C1)
'> /home/pi/x728bat.py
echo '
while True:
 print ("******************")
 print ("Voltage:%5.2fV" % readVoltage(bus))
 print ("Battery:%5i%%" % readCapacity(bus))

 if readCapacity(bus) == 100:
        print ("Battery FULL")
 if readCapacity(bus) < 20:
        print ("Battery Low")

#Set battery low voltage to shut down, you can modify the 3.00 to other value
 if readVoltage(bus) < 3.00:
                print ("Battery LOW!!!")
                print ("Shutdown in 10 seconds")
                time.sleep(10)
                GPIO.output(GPIO_PORT, GPIO.HIGH)
                time.sleep(3)
                GPIO.output(GPIO_PORT, GPIO.LOW)

 time.sleep(10)
' >> /home/pi/x728bat.py
sudo chmod +x /home/pi/x728bat.py
sudo sed -i "$ i python3 /home/pi/x728bat.py >/dev/null &" /etc/rc.local

#X728 AC Power loss / power adapter failure detection
#!/bin/bash

sudo sed -e '/button/ s/^#*/#/' -i /etc/rc.local

echo '#!/usr/bin/env python
import RPi.GPIO as GPIO

GPIO.setmode(GPIO.BCM)
GPIO.setup(6, GPIO.IN)

def my_callback(channel):
    if GPIO.input(6):     # if port 6 == 1
        print ("---AC Power Loss OR Power Adapter Failure---")
    else:                  # if port 6 != 1
        print ("---AC Power OK,Power Adapter OK---")

GPIO.add_event_detect(6, GPIO.BOTH, callback=my_callback)

print ("1.Make sure your power adapter is connected")
print ("2.Disconnect and connect the power adapter to test")
print ("3.When power adapter disconnected, you will see: AC Power Loss or Power Adapter Failure")
print ("4.When power adapter disconnected, you will see: AC Power OK, Power Adapter OK")

input("Testing Started")
' > /home/pi/x728pld.py
sudo chmod +x /home/pi/x728pld.py

sudo systemctl enable pigpiod

CUR_DIR=$(pwd)
sudo sed -i "$ i python3 ${CUR_DIR}/fan.py >/dev/null &" /etc/rc.local

#sudo echo "alias xoff='sudo x-c1-softsd.sh'" >> /home/pi/.bashrc
#sudo pigpiod
#python3 ${CUR_DIR}/fan.py&

echo "The installation is complete."
echo "Please run 'sudo reboot' to reboot the device."
echo "NOTE:"
echo "1. DON'T modify the name fold: $(basename ${CUR_DIR}), or the PWM fan will not work after reboot."
echo "2. fan.py is python file to control fan speed according temperature of CPU, you can modify it according your needs."
echo "3. PWM fan needs a PWM signal to start working. If fan doesn't work in third-party OS afer reboot only remove the YELLOW wire of fan to let the fan run immediately or contact us: info@geekworm.com."
