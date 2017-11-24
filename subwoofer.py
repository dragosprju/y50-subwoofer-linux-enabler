#!/usr/bin/env python

import subprocess
import atexit
import sys
import os
import time

from subprocess import call

############
# Settings #
############
# For when you don't have headphones in and you want custom volume balance
speakerBalance = 0
# For when YOU DO have headphones in and you want custom volume balance
# (broken debalanced headphones and whatnot)
headphonesBalance = 0
# This helps the subwoofer get the correct left/right stereo in so it sounds like
subwooferBalance = -25		# Default: -25
# This is extra volume for the subwoofer, independent of what stereo balance it gets as input
extraVolume = 11 		# Default: -11. New default: 11; 
pulseaudio_detect_intervals = 5 # Default: 5. No. of seconds between pulseaudio detects.

# These are needed so the detection of volume change / headphones plug in or out not be done
# for all of the enabled audio devices. Change to the alternatives if subwoofer doesn't enable
# or disable on such events.
devId = 1 # alternative would be 0
sinkNo = "1" # alternative would be "" for all

dev="/dev/snd/hwC1D0"

#############
# Functions #
#############

# Global variables
running = True
headphones_in = False
speakers_set = False
headphones_set = False
curr_volume = 0
pactl = None

# Subwoofer part
################

def enable_subwoofer():
  call(["sudo", "hda-verb", dev, "0x17", "SET_POWER", "0x0"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  call(["sudo", "hda-verb", dev, "0x1a", "SET_POWER", "0x0"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)

  call(["sudo", "hda-verb", dev, "0x17", "0x300", "0xb000"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  call(["sudo", "hda-verb", dev, "0x17", "0x707", "0x40"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  call(["sudo", "hda-verb", dev, "0x1a", "0x707", "0x25"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)

def disable_subwoofer():
  call(["sudo", "hda-verb", dev, "0x1a", "0x707", "0x20"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)

def set_subwoofer_volume(volumes):
  valL = 0xa000 + volumes[0]
  valR = 0x9000 + volumes[1]
  call(["sudo", "hda-verb", dev, "0x03", "0x300", hex(valL)], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  call(["sudo", "hda-verb", dev, "0x03", "0x300", hex(valR)], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  print "Subwoofer volumes set. Left: " + str(volumes[0]) + ". Right: " + str(volumes[1]) + "."

def calculate_subwoofer_volume(spk_vol, balance):
  balL = 100
  balR = 100
  if balance < 0:
    balL = 100
    balR = balR + balance
  else:
    balL = balL - balance
    balR = 100
  
  valL = 87 * spk_vol * balL / 100 / 100 + extraVolume
  valR = 87 * spk_vol * balR / 100 / 100 + extraVolume

  vals = calibrate87([valL, valR])

  return vals

def set_subwoofer():
  vol = get_biggest_volume()
  subVols = calculate_subwoofer_volume(vol, subwooferBalance)   
  set_subwoofer_volume(subVols)

# Speaker part
##############

def calculate_speaker_balance(spk_vol, balance):
  vol = get_biggest_volume()

  balL = 100
  balR = 100
  if balance < 0:
    balL = 100
    balR = balR + balance
  else:
    balL = balL - balance
    balR = 100

  valL = spk_vol * balL / 100
  valR = spk_vol * balR / 100
  
  return [valL, valR]   

def set_speaker_volumes(volumes):
  volumes = calibrate100(volumes)
  call(["amixer", "-D", "pulse", "set", "Master", str(volumes[0]) + "%," + str(volumes[1]) + "%"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  print "Speaker volumes set. Left: " + str(volumes[0]) + ". Right: " + str(volumes[1])

def set_speakers():
  global speakers_set
  global headphones_set

  if speakers_set:
    return
  else:
    speakers_set = True
    headphones_set = False

  vol = get_biggest_volume()
  spkVols = calculate_speaker_balance(vol, speakerBalance)   
  set_speaker_volumes( spkVols)  

def get_biggest_volume():
  volumes = get_volumes()

  if len(volumes) == 1:
    return volumes[0]
  if volumes[0] > volumes[1]:
    return volumes[0]
  else:
    return volumes[1]

def get_volumes():
  amixer = subprocess.Popen(["amixer", "-D", "pulse", "get", "Master"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  output = []
  for line in iter(amixer.stdout.readline, ''):
    if '%' in line:
      vol = line.split('[')[1].split('%]')[0]
      output.append(int(vol))
  
  return output     

# Headphones part
#################

def set_headphones():
  global headphones_set
  global speakers_set

  if headphones_set:
    return
  else:
    headphones_set = True
    speakers_set = False

  vol = get_biggest_volume()
  spkVols = calculate_speaker_balance(vol, headphonesBalance)   
  set_speaker_volumes(spkVols)   

def headphones_in_query():
  global headphones_in

  amixer = subprocess.Popen(["amixer", "-c", str(devId), "cget", "numid=22"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)

  i = 0  
  count = False
  for line in iter(amixer.stdout.readline, ''):
    if "numid=22" in line:
      count = True
    if count:
      i = i + 1
    if i == 3:
      if "values=off" in line:
        headphones_in = False
      elif "values=on" in line:
        headphones_in = True
      break   
  
  amixer.terminate() 

def check_headphones():
  headphones_in_query()
  if headphones_in:
    #print "Headphones in!"
    disable_subwoofer()
    set_headphones()
  else:
    #print "Headphones out!"
    enable_subwoofer()
    set_speakers()

# Additional functions
######################

def calibrate(volumes, limit):
  if volumes[0] > limit:
    volumes[0] = limit
  elif volumes[0] < 0:
    volumes[0] = 0

  if volumes[1] > limit:
    volumes[1] = limit
  elif volumes[1] < 0:
    volumes[1] = 0

  return [volumes[0], volumes[1]] 
  
def calibrate100(volumes):
  return calibrate(volumes, 100)

def calibrate87(volumes):
  return calibrate(volumes, 87)  

def check_volume(): 
  global curr_volume
  new_volume = get_biggest_volume()

  if curr_volume != new_volume:
    curr_volume = new_volume
    print "Volume change detected: ", curr_volume
    
    if headphones_in == False:
      set_subwoofer()

def on_exit():
  global pactl
  if pactl is not None:
    pactl.terminate()
  disable_subwoofer()

########
# Main #
########
if __name__ == "__main__":
  f = open("/home/dragos/args.log", "a")
  f.write("\r\n")
  f.write(str(sys.argv))
  f.close()
  if ("exit" in sys.argv) or (("pre" in sys.argv) and 
    (("suspend" in sys.argv) or ("hibernate" in sys.argv) or ("hybrid-sleep" in sys.argv))):
    on_exit()
    sys.exit(0)
  atexit.register(on_exit)

  pulseaudio_detected = False
  while pulseaudio_detected is False:
    pgrep = subprocess.Popen(["pgrep","-u",str(os.getuid()),"pulseaudio"], stdout=subprocess.PIPE)
    for line in iter(pgrep.stdout.readline, ''):
      if line.strip():
        print "Pulseaudio detected"
        pulseaudio_detected = True
      else:
        time.sleep(pulseaudio_detect_intervals)
    if pgrep is not None:
      pgrep.terminate()
    


  headphones_in_query()
  if headphones_in == False:
    enable_subwoofer()
    set_subwoofer()
    set_speakers()

  pactl = subprocess.Popen(["pactl", "subscribe"], stdout=subprocess.PIPE)
  for line in iter(pactl.stdout.readline, ''):
    if "Event 'change' on sink #" + sinkNo in line:
      check_headphones()
      check_volume()
      





