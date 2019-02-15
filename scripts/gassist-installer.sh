#!/bin/bash
# Copyright 2017 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
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
    echo ">>> Script must be run as '$RUN_AS'. Changing user..."
    exec sudo -u $RUN_AS $0
fi
clear;

sed 's/#.*//' ${GASSISTPI}Requirements/GassistPi-system-requirements.txt | xargs sudo apt-get install -y
sudo pip install pyaudio;

# Check OS Version
echo ""
echo ">>> Checking Raspberry Pi OS..."
if [[ $(cat /etc/os-release|grep "raspbian") ]]; then
if [[ $(cat /etc/os-release|grep "stretch") ]]; then
    osversion="Raspbian Stretch"
    echo ">>> You are running Raspbian Stretch!"
    echo ""
else
    osversion="Other Raspbian"
    echo ">>> Other version detected than Raspberry Stretch."
    echo ">>> Please install Raspberry Stretch!"
    echo ""
    exit 1
fi
elif [[ $(cat /etc/os-release|grep "armbian") ]]; then
if [[ $(cat /etc/os-release|grep "stretch") ]]; then
    osversion="Armbian Stretch"
    echo ">>> You are running Raspbian Stretch!"
    echo ""
else
    osversion="Other Armbian"
    echo ">>> Other version detected than Raspberry Stretch."
    echo ">>> Please install Raspberry Stretch!"
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
    echo ">>> You are running Raspbian Stretch!"
    echo ""
else
    osversion="Other OSMC"
    echo ">>> Other version detected than Raspberry Stretch."
    echo ">>> Please install Raspberry Stretch!"
    echo ""
    exit 1
fi
elif [[ $(cat /etc/os-release|grep "ubuntu") ]]; then
if [[ $(cat /etc/os-release|grep "bionic") ]]; then
    osversion="Ubuntu Bionic"
    echo ">>> You are running Ubuntu Bionic"
    echo ""
else
    osversion="Other Ubuntu"
    echo ">>> Other version detected than Ubuntu Bionic."
    echo ">>> Please install Raspberry Stretch!"
    echo ""
    exit 1
fi
fi

#Check CPU architecture
if [[ $(uname -m|grep "armv7") ]] || [[ $(uname -m|grep "x86_64") ]]; then
    devmodel="armv7"
    echo ">>> Raspberry Pi board supports the 'OK-Google' Hotword!"
    echo ">>> You can also trigger Google Assistant using a custom wakeword."
    echo ""
else
    devmodel="armv6"
    echo ">>> Raspberry Pi board does not support 'OK-Google' Hotword!"
    echo ">>> You can trigger Google Assistant using the pushbutton or a custom wakeword."
    echo ""
fi

#Check Board Model
if [[ $(cat /proc/cpuinfo|grep "BCM") ]]; then
    board="Raspberry"
    echo ">>> GPIO Pins automatically unlocked for Google Assistant!"
    echo ""
else
    board="Others"
    echo ">>> GPIO Pins can't be unlocked automatically for Google Assistant."
    echo ""
fi

if [[ $osversion != "Raspbian Stretch" ]];then
    echo ">>> Snowboy wrappers provided require a Raspberry Pi running Raspbian Stretch."
    echo ">>> Custom Snowboy wrappers need to be compiled for your OS version."
    echo ""
    echo ">>> Installing swig..."
    echo ""
    if [ ! -d ${HOMEDIR}programs/libraries/swig/ ]; then
        sudo mkdir -p programs/libraries/ && cd programs/libraries
        sudo git clone https://github.com/swig/swig.git
    fi
    cd ${HOMEDIR}programs/libraries/swig/
    sudo ./autogen.sh
    sudo ./configure
    sudo make
    sudo make install
    echo ""
    echo ">>> Compiling custom Snowboy python3 wrapper"
    echo ""
    cd ~/programs
    if [ ! -d ${HOMEDIR}programs/snowboy/ ]; then
        sudo git clone https://github.com/Kitt-AI/snowboy.git
    fi
    cd ${HOMEDIR}programs/snowboy/swig/Python3
    sudo make;
    if [ -e ${HOMEDIR}programs/snowboy/swig/Python3/_snowboydetect.so ]; then
        echo ">>> Copying Snowboy files to Google Assistant directory!"
        sudo \cp -f ./_snowboydetect.so ${GASSISTPI}/src/_snowboydetect.so
        sudo \cp -f ./snowboydetect.py ${GASSISTPI}/src/snowboydetect.py
    else
        echo ">>> Error while compiling the wrappers. Try again or check the errors above!";
    fi
fi

cd ${HOMEDIR};

if [[ $devmodel = "armv7" ]];then
    echo ""
    echo ">>> Changing service files for OK-Google Hotword!"
    echo ""
    sed -i '/pushbutton.py/d' ${GASSISTPI}/systemd/gassistpi.service
    sed -i 's/saved-model-id/'$MODELID'/g' ${GASSISTPI}/systemd/gassistpi.service
else
    echo ">>> Changing service files for the Google Assistant pushbutton or a custom wakeword."
    echo ""
    sed -i '/main.py/d' ${GASSISTPI}/systemd/gassistpi.service
    sed -i 's/saved-model-id/'$MODELID'/g' ${GASSISTPI}/systemd/gassistpi.service
    sed -i 's/created-project-id/'$GOOGLEPROJECTID'/g' ${GASSISTPI}/systemd/gassistpi.service
fi

sed -i 's/__USER__/'${USER}'/g' ${GASSISTPI}/systemd/gassistpi.service

cd ${HOMEDIR};

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
                     --save --headless --client-secrets $CLIENTSECRET

echo ">>> Google Assistant test..."

if [[ $devmodel = "armv7" ]];then
    googlesamples-assistant-hotword --project_id $GOOGLEPROJECTID --device_model_id $MODELID
else
    googlesamples-assistant-pushtotalk --project-id $GOOGLEPROJECTID --device-model-id $MODELID
fi
