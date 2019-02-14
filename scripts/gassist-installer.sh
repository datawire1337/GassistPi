#!/bin/bash
# Copyright 2017 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
set -o errexit

scripts_dir="$(dirname "${BASH_SOURCE[0]}")"
GASSISTPI="$(realpath $(dirname ${BASH_SOURCE[0]})/..)"

# Variabelen definiëren
HOMEDIR="/home/${USER}/";
PIXXIEDIR="${HOMEDIR}pixxie/";
GITHUB_USER="datawire1337";
GITHUB_PW="Hamster1337!";
GITHUB_AUTH="${GITHUB_USER}:${GITHUB_PW}";
GITHUB_TOKEN="9c72ef04dc4af6c40a4759f1a02c1c7f6d19353f";
PIXXIEGIT="https://${GITHUB_ATUH}@github.com/datawire1337/PIXXIE.git";
RASPIAUDIO="/home/${USER}/pixxie/software/raspiaudio/";
GASSISTPI="${HOMEDIR}GassistPi/";
GASSISTPIGIT="https://github.com/datawire1337/GassistPi.git";
NEWVERSIONCHECKER="${HOMEDIR}nvchecker/"
NEWVERSIONCHECKERGIT="https://github.com/datawire1337/nvchecker.git";
INSTALLDIR="${PIXXIEDIR}install/";
ETCDIR="${PIXXIEDIR}etc/";
VIRTUALDIR="${GASSISTPI}env/";
DEVICEREGISTRATIONURL="https://console.actions.google.com/u/0/project/pixxie-4ac95/deviceregistration/";
GOOGLEPROJECTID="pixxie-4ac95";
NEW_UUID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1);
DEVICEID="${GOOGLEPROJECTID}-PiXXiE-${NEW_UUID}";
MODELID="${GOOGLEPROJECTID}-PiXXiE";
GOOGLEPRODUCTNAME="PiXXiE";
GOOGLEMANUFACTURER='Digital Monitoring Systems NV';
GOOGLEDEVICETYPE="action.devices.types.LIGHT";
CLIENTSECRET="${INSTALLDIR}client_secret_339523006779-bl8qitgg4ohfv69t4fh915m61edh52v4.apps.googleusercontent.com.json";
INSTALL_SCRIPT="bash ${INSTALLDIR}install.sh"
# CLIENTSECRET2="${INSTALLDIR}client_secret_339523006779-7ejm065jjblorsjc7ltf1gm0cqgmt49h.apps.googleusercontent.com.json";

# make sure we're running as the owner of the checkout directory
RUN_AS="$(ls -ld "$scripts_dir" | awk 'NR==1 {print $3}')"
if [ "$USER" != "$RUN_AS" ]
then
    echo "This script must run as $RUN_AS, trying to change user..."
    exec sudo -u $RUN_AS $0
fi
clear
# echo ""
# read -r -p "Enter the your full credential file name including the path and .json extension: " credname
# echo ""
# read -r -p "Enter the your Google Cloud Console Project-Id: " GOOGLEPROJECTID
# echo ""
# read -r -p "Enter the MODELID that was generated in the actions console: " MODELID
# echo ""
# echo "Your Model-Id used for the project is: $MODELID" >> /home/${USER}/MODELID.txt

sudo apt-get update -y
sed 's/#.*//' ${GASSISTPI}Requirements/GassistPi-system-requirements.txt | xargs sudo apt-get install -y
sudo pip install pyaudio

#Check OS Version
echo ""
echo "===========================Checking OS Compatability========================="
echo ""
if [[ $(cat /etc/os-release|grep "raspbian") ]]; then
  if [[ $(cat /etc/os-release|grep "stretch") ]]; then
    osversion="Raspbian Stretch"
    echo ""
    echo "===========You are running the installer on Stretch=========="
    echo ""
  else
    osversion="Other Raspbian"
    echo ""
    echo "===========You are advised to use the Stretch version of the OS=========="
    echo "===========Exiting the installer=========="
    echo ""
    exit 1
  fi
elif [[ $(cat /etc/os-release|grep "armbian") ]]; then
  if [[ $(cat /etc/os-release|grep "stretch") ]]; then
    osversion="Armbian Stretch"
    echo ""
    echo "===========You are running the installer on Stretch=========="
    echo ""
  else
    osversion="Other Armbian"
    echo ""
    echo "===========You are advised to use the Stretch version of the OS=========="
    echo "===========Exiting the installer=========="
    echo ""
    exit 1
  fi
elif [[ $(cat /etc/os-release|grep "osmc") ]]; then
  osmcversion=$(grep VERSION_ID /etc/os-release)
  osmcversion=${osmcversion//VERSION_ID=/""}
  osmcversion=${osmcversion//'"'/""}
  osmcversion=${osmcversion//./-}
  osmcversiondate=$(date -d $osmcversion +%s)
  export LC_ALL=C.UTF-8
  export LANG=C.UTF-8
  if (($osmcversiondate > 1512086400)); then
    osversion="OSMC Stretch"
    echo ""
    echo "===========You are running the installer on Stretch=========="
    echo ""
  else
    osversion="Other OSMC"
    echo ""
    echo "===========You are advised to use the Stretch version of the OS=========="
    echo "===========Exiting the installer=========="
    echo ""
    exit 1
  fi
elif [[ $(cat /etc/os-release|grep "ubuntu") ]]; then
  if [[ $(cat /etc/os-release|grep "bionic") ]]; then
    osversion="Ubuntu Bionic"
    echo ""
    echo "===========You are running the installer on Bionic=========="
    echo ""
  else
    osversion="Other Ubuntu"
    echo ""
    echo "===========You are advised to use the Bionic version of the OS=========="
    echo "===========Exiting the installer=========="
    echo ""
    exit 1
  fi
fi

#Check CPU architecture
if [[ $(uname -m|grep "armv7") ]] || [[ $(uname -m|grep "x86_64") ]]; then
	devmodel="armv7"
  echo ""
  echo "===========Your board supports Ok-Google Hotword. You can also trigger the assistant using custom-wakeword=========="
  echo ""
else
	devmodel="armv6"
  echo ""
  echo "==========Your board does not support Ok-Google Hotword. You need to trigger the assistant using pushbutton/custom-wakeword=========="
  echo ""
fi

#Check Board Model
if [[ $(cat /proc/cpuinfo|grep "BCM") ]]; then
	board="Raspberry"
  echo ""
  echo "===========GPIO pins can be used with the assistant=========="
  echo ""
else
	board="Others"
  echo ""
  echo "===========GPIO pins cannot be used by default with the assistant. You need to figure it out by yourselves=========="
  echo ""
fi

if [[ $osversion != "Raspbian Stretch" ]];then
  echo "==========Snowboy wrappers provied with the project are for Raspberry Pi boards running Raspbian Stretch. Custom snowboy wrappers need to be compiled for your setup=========="
  echo ""
  echo "==========Installing Swig========="
  echo ""
  if [ ! -d /home/${USER}/programs/libraries/swig/ ]; then
    sudo mkdir -p programs/libraries/ && cd programs/libraries
    sudo git clone https://github.com/swig/swig.git
  fi
  cd /home/${USER}/programs/libraries/swig/
  sudo ./autogen.sh
  sudo ./configure
  sudo make
  sudo make install
  echo ""
  echo "==========Compiling custom Snowboy Python3 wrapper=========="
  echo ""
  cd ~/programs
  if [ ! -d /home/${USER}/programs/snowboy/ ]; then
    sudo git clone https://github.com/Kitt-AI/snowboy.git
  fi
  cd /home/${USER}/programs/snowboy/swig/Python3
  sudo make

  if [ -e /home/${USER}/programs/snowboy/swig/Python3/_snowboydetect.so ]; then
    echo "=========Copying Snowboy files to GassistPi directory=========="
    sudo \cp -f ./_snowboydetect.so ${GASSISTPI}/src/_snowboydetect.so
    sudo \cp -f ./snowboydetect.py ${GASSISTPI}/src/snowboydetect.py
  else
    echo "==========Something has gone wrong while compiling the wrappers. Try again or go through the errors above=========="
  fi
fi

cd /home/${USER}/
echo ""
echo ""
echo "==========Changing particulars in service files=========="

if [[ $devmodel = "armv7" ]];then
  echo ""
  echo ""
  echo "==========Changing particulars in service files for Ok-Google hotword=========="
  sed -i '/pushbutton.py/d' ${GASSISTPI}/systemd/gassistpi.service
  sed -i 's/saved-model-id/'$MODELID'/g' ${GASSISTPI}/systemd/gassistpi.service
else
  echo ""
  echo ""
  echo "==========Changing particulars in service files for Pushbutton/Custom-wakeword=========="
  sed -i '/main.py/d' ${GASSISTPI}/systemd/gassistpi.service
  sed -i 's/saved-model-id/'$MODELID'/g' ${GASSISTPI}/systemd/gassistpi.service
  sed -i 's/created-project-id/'$GOOGLEPROJECTID'/g' ${GASSISTPI}/systemd/gassistpi.service
fi

sed -i 's/__USER__/'${USER}'/g' ${GASSISTPI}/systemd/gassistpi.service

python3 -m venv env
env/bin/python -m pip install --upgrade pip setuptools wheel
source env/bin/activate

pip install -r ${GASSISTPI}/Requirements/GassistPi-pip-requirements.txt

if [[ $board = "Raspberry" ]] && [[ $osversion != "OSMC Stretch" ]];then
	pip install RPi.GPIO==0.6.3
fi

if [[ $devmodel = "armv7" ]];then
	pip install google-assistant-library==1.0.1
else
  pip install --upgrade --no-binary :all: grpcio
fi

pip install google-assistant-grpc==0.2.1
pip install google-assistant-sdk==0.5.1
pip install google-assistant-sdk[samples]==0.5.1
google-oauthlib-tool --scope https://www.googleapis.com/auth/assistant-sdk-prototype \
          --scope https://www.googleapis.com/auth/gcm \
          --save --headless --client-secrets $credname

echo "Testing the installed google assistant. Make a note of the generated Device-Id"

if [[ $devmodel = "armv7" ]];then
	googlesamples-assistant-hotword --project_id $GOOGLEPROJECTID --device_model_id $MODELID
else
	googlesamples-assistant-pushtotalk --project-id $GOOGLEPROJECTID --device-model-id $MODELID
fi
