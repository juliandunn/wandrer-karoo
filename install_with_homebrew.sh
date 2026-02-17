#!/bin/bash

# Copy of macos_install.cmd, but assuming that the user has installed Android platform tools
# via Homebrew

wandrer_package="earth.wandrer.karoo.app"
starting_activity="earth.wandrer.android.app.MainActivity"

## DO NOT UPDATE BELOW THIS LINE ------------

printf "\nIf you experience any issues installing Wandrer please contact craig@wandrer.earth and include a copy of the output below.\n"

# double clicking this will start in user's home directory
cd `dirname $0`

# cleanup from any previous run
rm devices > /dev/null

set -e # since above rm calls might fail, only now do we exit if any command fails

# confirm there is an apk in this directory to install
printf "\nValidating apk... \n"
APK=wandrer.apk
if [ -f "$APK" ]; then
    printf "  Valid\n"
else
    printf "  Cannot find ${APK}. Make sure the supplied install is in the same directory.\n"
    exit -1
fi

# confirm adb version
printf "\nChecking ADB:\n"
# pipe to sed to add two spaces to each output line
adb --version | sed 's/^/  /'

# adb to find device
printf "\nFinding device...\n"
adb devices \
 | grep -v '^[[:space:]]*$' \
 | grep -A10 "List of devices attached" > devices

device_count=($(wc -l devices))
device_count=$((${device_count[0]} - 1)) # get just the count and remove one for the "List of devices attached" line.

if [[ $device_count == 0 ]]; then
  printf "  No device found. Make sure that Developer Options are enabled and that device is connected and powered on.\n\n"
  exit -1
fi

if [[ $device_count -gt 1 ]]; then
 printf "  More than one device connected. Please connect just Karoo and try again.\n\n"
 exit -1
fi

# Looking at adb ids, Karoo2 and Karoo3 start with KAROO2, Karoo1 doesn't have a common pattern.
# So instead of checking device ID, instead check ro.products.
mfg=$(adb shell getprop | grep ro.product.manufacturer)
model=$(adb shell getprop | grep ro.product.model)

if [[ $mfg == *"Hammerhead"* ]] ; then
 # "k2" matches both the K2 and K3 (which is weirdly called "k24"
 if [[ "$model" == *"k2"* || "$model" == *"Karoo"* ]] ; then
    printf "  Found Hammerhead device.\n"
    printf "\nInstalling Wandrer app...\n" 
    adb install -r ${APK} > /dev/null
    
    # print newly installed version name
    version=$(adb shell dumpsys package ${wandrer_package} \
      | grep versionName \
      | sed 's/versionName=//')
    printf "  Installed version: ${version}\n  Rebooting...\n"
    adb shell pm clear ${wandrer_package} > /dev/null
    adb reboot > /dev/null
    sleep 50 # seconds, just a guess
    adb shell am start -n ${wandrer_package}/${starting_activity} > /dev/null
    printf "  All done. You now need to login to Wandrer app.\n\n"
    exit 0 
  fi  
fi

# clean up
rm devices > /dev/null
  
printf "  Device is not Hammerhead Karoo 1, Karoo 2, or Karoo 3.\n\n"
