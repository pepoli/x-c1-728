#!/usr/bin/python
import pigpio
import time

servo = 18

pwm = pigpio.pi()
pwm.set_mode(servo, pigpio.OUTPUT)
pwm.set_PWM_frequency( servo, 25000 )
pwm.set_PWM_range(servo, 100)
while(1):
     #get CPU temp
     file = open("/sys/class/thermal/thermal_zone0/temp")
     temp = float(file.read()) / 1000.00
     temp = float('%.2f' % temp)
     file.close()

     if(temp > 40):
          pwm.set_PWM_dutycycle(servo, 40)
          print ("Temperature : %5.2f deg" % temp)
     if(temp > 50):
          pwm.set_PWM_dutycycle(servo, 60)
          print ("Temperature : %5.2f deg" % temp)
     if(temp > 60):
          pwm.set_PWM_dutycycle(servo, 80)
          print ("Temperature : %5.2f deg" % temp)
     if(temp > 70):
          pwm.set_PWM_dutycycle(servo, 100)
          print ("Temperature : %5.2f deg" % temp)
     if(temp < 40):
          pwm.set_PWM_dutycycle(servo, 0)
          print ("Temperature : %5.2f deg" % temp)
     time.sleep(10)
