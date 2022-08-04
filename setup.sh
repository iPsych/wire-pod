#!/bin/bash

echo

UNAME=$(uname -a)
CPUINFO=$(cat /proc/cpuinfo)

if [[ -f /usr/bin/apt ]]; then
   TARGET="debian"
   echo "Debian-based Linux confirmed."
elif [[ -f /usr/bin/pacman ]]; then
   TARGET="arch"
   echo "Arch Linux confirmed."
else
   echo "This OS is not supported. This script currently supports Arch and Debian-based Linux."
   exit 1
fi

if [[ "${UNAME}" == *"x86_64"* ]]; then
   ARCH="x86_64"
   echo "amd64 architecture confirmed."
elif [[ "${UNAME}" == *"aarch64"* ]]; then
   ARCH="aarch64"
   echo "aarch64 architecture confirmed."
elif [[ "${UNAME}" == *"armv7l"* ]]; then
   ARCH="armv7l"
   echo "armv7l architecture confirmed."
else
   echo "Your CPU architecture not supported. This script currently supports x86_64, aarch64, and armv7l."
   exit 1
fi

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. sudo ./setup.sh"
   exit 1
fi

if [[ ! -d ./chipper ]]; then
   echo "Script is not running in the jank-escape-pod/ directory or chipper folder is missing. Exiting."
   exit 1
fi

if [[ $1 != "-f" ]]; then
   if [[ ${ARCH} == "x86_64" ]]; then
      if [[ "${CPUINFO}" == *"avx"* ]]; then
         echo "AVX support confirmed."
      else
         echo "This CPU does not support AVX. This is required for text to speech. Exiting."
         echo "If you would like to bypass this, run the script like this: './setup.sh -f'"
         exit 1
      fi
   fi
fi

echo "Checks have passed!"
echo

function getPackages() {
   if [[ ! -f ./vector-cloud/packagesGotten ]]; then
      echo "Installing required packages (ffmpeg, golang, wget, openssl, net-tools, iproute2, sox, opus)"
      if [[ ${TARGET} == "debian" ]]; then
         apt update -y
         apt install -y wget openssl net-tools libsox-dev libopus-dev make iproute2 xz-utils libopusfile-dev pkg-config gcc curl
      elif [[ ${TARGET} == "arch" ]]; then
         pacman -Sy --noconfirm
         sudo pacman -S --noconfirm wget openssl net-tools sox opus make iproute2 opusfile curl
      fi
      touch ./vector-cloud/packagesGotten
      echo
      echo "Installing golang binary package"
      mkdir golang
      cd golang
      if [[ ! -f /usr/local/go/bin/go ]]; then
      if [[ ${ARCH} == "x86_64" ]]; then
         wget -q --show-progress https://go.dev/dl/go1.18.2.linux-amd64.tar.gz
         rm -rf /usr/local/go && tar -C /usr/local -xzf go1.18.2.linux-amd64.tar.gz
         export PATH=$PATH:/usr/local/go/bin
      elif [[ ${ARCH} == "aarch64" ]]; then
         wget -q --show-progress https://go.dev/dl/go1.18.2.linux-arm64.tar.gz
         rm -rf /usr/local/go && tar -C /usr/local -xzf go1.18.2.linux-arm64.tar.gz
         export PATH=$PATH:/usr/local/go/bin
      elif [[ ${ARCH} == "armv7l" ]]; then
         wget -q --show-progress https://go.dev/dl/go1.18.2.linux-armv6l.tar.gz
         rm -rf /usr/local/go && tar -C /usr/local -xzf go1.18.2.linux-armv6l.tar.gz
         export PATH=$PATH:/usr/local/go/bin
      fi
      fi
      cd ..
      rm -rf golang
   else
      echo "Required packages already gotten."
   fi
   echo
}

function buildCloud() {
   echo
   echo "Installing docker"
   if [[ ${TARGET} == "debian" ]]; then
      apt update -y
      apt install -y docker.io
   elif [[ ${TARGET} == "arch" ]]; then
      pacman -Sy --noconfirm
      sudo pacman -S --noconfirm docker
   fi
   systemctl start docker
   echo
   cd vector-cloud
   ./build.sh
   cd ..
   echo
   echo "./vector-cloud/build/vic-cloud built!"
   echo
}

function buildChipper() {
   echo
   cd chipper
   if [[ ${ARCH} != "x86_64" ]]; then
      echo
      echo "This system is not x86_64. This program will still work, but this system will be considered slow and STT will be done to account for slower hardware."
      echo "If you feel like this system is fast enough for regular STT processing, run: sudo rm -f ./chipper/slowsys"
      echo
      touch slowsys
   fi
   echo
   cd ..
}

function getSTT() {
   if [[ ! -f ./stt/completed ]]; then
      echo "Getting STT assets"
      if [[ -d /root/.coqui ]]; then
         rm -rf /root/.coqui
      fi
      origDir=$(pwd)
      mkdir /root/.coqui
      cd /root/.coqui
      if [[ ${ARCH} == "x86_64" ]]; then
         wget -q --show-progress https://github.com/coqui-ai/STT/releases/download/v1.3.0/native_client.tflite.Linux.tar.xz
         tar -xf native_client.tflite.Linux.tar.xz
         rm -f ./native_client.tflite.Linux.tar.xz
      elif [[ ${ARCH} == "aarch64" ]]; then
         wget -q --show-progress https://github.com/coqui-ai/STT/releases/download/v1.3.0/native_client.tflite.linux.aarch64.tar.xz
         tar -xf native_client.tflite.linux.aarch64.tar.xz
         rm -f ./native_client.tflite.linux.aarch64.tar.xz
      elif [[ ${ARCH} == "armv7l" ]]; then
         wget -q --show-progress https://github.com/coqui-ai/STT/releases/download/v1.3.0/native_client.tflite.linux.armv7.tar.xz
         tar -xf native_client.tflite.linux.armv7.tar.xz
         rm -f ./native_client.tflite.linux.armv7.tar.xz
      fi
      cd ${origDir}/chipper
      export CGO_LDFLAGS="-L$HOME/.coqui/"
      export CGO_CXXFLAGS="-I$HOME/.coqui/"
      export LD_LIBRARY_PATH="$HOME/.coqui/:$LD_LIBRARY_PATH"
      /usr/local/go/bin/go get -u github.com/asticode/go-asticoqui/...
      /usr/local/go/bin/go get github.com/asticode/go-asticoqui
      /usr/local/go/bin/go install github.com/asticode/go-asticoqui
      cd ${origDir}
      mkdir -p stt
      cd stt
      echo "Getting STT model..."
      wget -q --show-progress https://coqui.gateway.scarf.sh/english/coqui/v1.0.0-large-vocab/model.tflite
      echo "Getting STT scorer..."
      wget -q --show-progress https://coqui.gateway.scarf.sh/english/coqui/v1.0.0-large-vocab/large_vocabulary.scorer
      echo
      touch completed
      echo "STT assets successfully downloaded!"
      cd ..
   else
      echo "STT assets already there!"
   fi
}

function IPDNSPrompt() {
   read -p "Enter a number (1): " yn
   case $yn in
      "1" ) SANPrefix="IP";;
      "2" ) SANPrefix="DNS";;
      "" ) SANPrefix="IP";;
      * ) echo "Please answer with 1 or 2."; IPDNSPrompt;;
   esac
}

function IPPrompt() {
   IPADDRESS=$(ip -4 addr | grep $(ip addr | awk '/state UP/ {print $2}' | sed 's/://g') | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
   read -p "Enter the IP address of the machine you are running this script on (${IPADDRESS}): " ipaddress
   if [[ ! -n ${ipaddress} ]]; then
      address=${IPADDRESS}
   else
      address=${ipaddress}
   fi
}

function DNSPrompt() {
   read -p "Enter the domain you would like to use: " dnsurl
   if [[ ! -n ${dnsurl} ]]; then
      echo "You must enter a domain."
      DNSPrompt
   fi
   address=${dnsurl}
}

function generateCerts() {
   echo
   echo "Creating certificates"
   echo
   echo "Would you like to use your IP address or a domain for the Subject Alt Name?"
   echo "1: IP address (recommended)"
   echo "2: Domain"
   IPDNSPrompt
   if [[ ${SANPrefix} == "IP" ]]; then
      IPPrompt
   else
      DNSPrompt
   fi
   rm -rf ./certs
   mkdir certs
   cd certs
   echo ${address} > address
   echo "Creating san config"
   echo "[req]" > san.conf
   echo "default_bits  = 4096" >> san.conf
   echo "default_md = sha256" >> san.conf
   echo "distinguished_name = req_distinguished_name" >> san.conf
   echo "x509_extensions = v3_req" >> san.conf
   echo "prompt = no" >> san.conf
   echo "[req_distinguished_name]" >> san.conf
   echo "C = US" >> san.conf
   echo "ST = VA" >> san.conf
   echo "L = SomeCity" >> san.conf
   echo "O = MyCompany" >> san.conf
   echo "OU = MyDivision" >> san.conf
   echo "CN = ${address}" >> san.conf
   echo "[v3_req]" >> san.conf
   echo "keyUsage = nonRepudiation, digitalSignature, keyEncipherment" >> san.conf
   echo "extendedKeyUsage = serverAuth" >> san.conf
   echo "subjectAltName = @alt_names" >> san.conf
   echo "[alt_names]" >> san.conf
   echo "${SANPrefix}.1 = ${address}" >> san.conf
   echo "Generating key and cert"
   openssl req -x509 -nodes -days 730 -newkey rsa:2048 -keyout cert.key -out cert.crt -config san.conf
   echo
   echo "Certificates generated!"
   cd ..
}

function makeSource() {
   if [[ ! -f ./certs/address ]]; then
      echo "You need to generate certs first!"
      exit 0
   fi
   cd chipper
   rm -f ./source.sh
   read -p "What port would you like to use? (443): " portPrompt
   if [[ -n ${portPrompt} ]]; then
      port=${portPrompt}
   else
      port="443"
   fi
   if netstat -pln | grep :${port}; then
      echo
      netstat -pln | grep :${port}
      echo
      echo "Something may be using port ${port}. Make sure that port is free before you start chipper."
   fi
   read -p "What port would you like to use for the HTTP webserver used for custom intents, bot configuration, etc? (8080): " webportPrompt
   if [[ -n ${webportPrompt} ]]; then
      webport=${webportPrompt}
   else
      webport="8080"
   fi
   echo
   function weatherPrompt() {
   echo "Would you like to setup weather commands? This involves creating a free account at https://www.weatherapi.com/ and putting in your API key."
   echo "Otherwise, placeholder values will be used."
   echo
   echo "1: Yes"
   echo "2: No"
   read -p "Enter a number (1): " yn
   case $yn in
      "1" ) weatherSetup="true";;
      "2" ) weatherSetup="false";;
      "" ) weatherSetup="true";;
      * ) echo "Please answer with 1 or 2."; weatherPrompt;;
   esac
   }
   weatherPrompt
   if [[ ${weatherSetup} == "true" ]]; then
   function weatherKeyPrompt() {
      echo
      echo "Create an account at https://www.weatherapi.com/ and enter the API key it gives you."
      echo "If you have changed your mind, enter Q to continue without weather commands."
      echo
      read -p "Enter your API key: " weatherAPI
      if [[ ! -n ${weatherAPI} ]]; then
         echo "You must enter an API key. If you have changed your mind, you may also enter Q to continue without weather commands."
         weatherKeyPrompt
      fi
      if [[ ${weatherAPI} == "Q" ]]; then
         weatherSetup="false";
      fi
   }
   weatherKeyPrompt
   function weatherUnitPrompt() {
   echo "What temperature unit would you like to use?"
   echo
   echo "1: Fahrenheit"
   echo "2: Celsius"
   read -p "Enter a number (1): " yn
   case $yn in
      "1" ) weatherUnit="F";;
      "2" ) weatherUnit="C";;
      "" ) weatherUnit="F";;
      * ) echo "Please answer with 1 or 2."; weatherUnitPrompt;;
   esac
   }
   weatherUnitPrompt
   fi
   function houndifyPrompt() {
   echo
   echo "Would you like to setup knowledge graph (I have a question) commands? This involves creating a free account at https://www.houndify.com/signup and putting in your Client Key and Client ID."
   echo "Note: It may seem like you only get a trial, but there is an actual free tier with 100 free requests per day."
   echo "This is not required, and if you choose 2 then placeholder values will be used. And if you change your mind later, just run ./setup.sh with the 5th option."
   echo
   echo "1: Yes"
   echo "2: No"
   read -p "Enter a number (1): " yn
   case $yn in
      "1" ) knowledgeSetup="true";;
      "2" ) knowledgeSetup="false";;
      "" ) knowledgeSetup="true";;
      * ) echo "Please answer with 1 or 2."; houndifyPrompt;;
   esac
   }
   houndifyPrompt
   if [[ ${knowledgeSetup} == "true" ]]; then
      function houndifyIDPrompt() {
      echo
      echo "Create an account at https://www.houndify.com/signup and enter the Client ID (not Key) it gives you."
      echo "If you have changed your mind, enter Q to continue without knowledge graph commands."
      echo
      read -p "Enter your Client ID: " knowledgeID
      if [[ ! -n ${knowledgeID} ]]; then
         echo "You must enter a Houndify Client ID. If you have changed your mind, you may also enter Q to continue without weather commands."
         houndifyIDPrompt
      fi
      if [[ ${knowledgeID} == "Q" ]]; then
         knowledgeSetup="false";
      fi
      }
      function houndifyKeyPrompt() {
      echo
      echo "Now enter the Houndify Client Key (not ID)."
      echo
      read -p "Enter your Client Key: " knowledgeKey
      if [[ ! -n ${knowledgeKey} ]]; then
         echo "You must enter a Houndify Client Key."
         houndifyKeyPrompt
      fi
      if [[ ${knowledgeKey} == "Q" ]]; then
         knowledgeSetup="false";
      fi
      }
      houndifyIDPrompt
      if [[ ${knowledgeSetup} == "true" ]]; then
         houndifyKeyPrompt
      fi
   fi
   echo "export DDL_RPC_PORT=${port}" > source.sh
   echo 'export DDL_RPC_TLS_CERTIFICATE=$(cat ../certs/cert.crt)' >> source.sh
   echo 'export DDL_RPC_TLS_KEY=$(cat ../certs/cert.key)' >> source.sh
   echo "export DDL_RPC_CLIENT_AUTHENTICATION=NoClientCert" >> source.sh
   if [[ ${weatherSetup} == "true" ]]; then
      echo "export WEATHERAPI_ENABLED=true" >> source.sh
      echo "export WEATHERAPI_KEY=${weatherAPI}" >> source.sh
      echo "export WEATHERAPI_UNIT=${weatherUnit}" >> source.sh
   else 
      echo "export WEATHERAPI_ENABLED=false" >> source.sh
   fi
   if [[ ${knowledgeSetup} == "true" ]]; then
      echo "export HOUNDIFY_ENABLED=true" >> source.sh
      echo "export HOUNDIFY_CLIENT_KEY=${knowledgeKey}" >> source.sh
      echo "export HOUNDIFY_CLIENT_ID=${knowledgeID}" >> source.sh
   else 
      echo "export HOUNDIFY_ENABLED=false" >> source.sh
   fi
   echo "export WEBSERVER_PORT=${webport}" >> source.sh
   echo "export DEBUG_LOGGING=true" >> source.sh
   cd ..
   echo
   echo "Created source.sh file!"
   echo
   cd certs
   echo "Creating server_config.json for robot"
   echo '{"jdocs": "jdocs.api.anki.com:443", "tms": "token.api.anki.com:443", "chipper": "REPLACEME", "check": "conncheck.global.anki-services.com/ok", "logfiles": "s3://anki-device-logs-prod/victor", "appkey": "oDoa0quieSeir6goowai7f"}' > server_config.json
   address=$(cat address)
   sed -i "s/REPLACEME/${address}:${port}/g" server_config.json
   cd ..
   echo "Created!"
   echo
}

function scpToBot() {
   if [[ ! -n ${botAddress} ]]; then
      echo "To copy vic-cloud and server_config.json to your OSKR robot, run this script like this:"
      echo "Usage: sudo ./setup.sh scp <vector's ip> <path/to/ssh-key>"
      echo "Example: sudo ./setup.sh scp 192.168.1.150 /home/wire/id_rsa_Vector-R2D2"
      echo
      echo "If your Vector is on Wire's custom software or you have an old dev build, you can run this command without an SSH key:"
      echo "Example: sudo ./setup.sh scp 192.168.1.150"
      echo
      exit 0
   fi
   if [[ ! -f ./certs/server_config.json ]]; then
      echo "server_config.json file missing. You need to generate this file with ./setup.sh's 6th option."
      exit 0
   fi
   if [[ ! -n ${keyPath} ]]; then
      echo
      if [[ ! -f ./ssh_root_key ]]; then
         echo "Key not provided, downloading ssh_root_key..."
         wget http://wire.my.to:81/ssh_root_key
      else
         echo "Key not provided, using ./ssh_root_key (already there)..."
      fi
      chmod 600 ./ssh_root_key
      keyPath="./ssh_root_key"
   fi
   if [[ ! -f ${keyPath} ]]; then
      echo "The key that was provided was not found. Exiting."
      exit 0
   fi
   ssh -i ${keyPath} root@${botAddress} "cat /build.prop" > /tmp/sshTest 2>> /tmp/sshTest
   botBuildProp=$(cat /tmp/sshTest)
   if [[ "${botBuildProp}" == *"no mutual signature"* ]]; then
      echo
      echo "An entry must be made to the ssh config for this to work. Would you like the script to do this?"
      echo "1: Yes"
      echo "2: No (exit)"
      echo
      function rsaAddPrompt() {
      read -p "Enter a number (1): " yn
      case $yn in
        "1" ) echo;;
        "2" ) exit 0;;
        "" ) echo;;
        * ) echo "Please answer with 1 or 2."; rsaAddPrompt;;
      esac
      }
      rsaAddPrompt
      echo "PubkeyAcceptedKeyTypes +ssh-rsa" >> /etc/ssh/ssh_config
      botBuildProp=$(ssh -i ${keyPath} root@${botAddress} "cat /build.prop")
   fi
   if [[ ! "${botBuildProp}" == *"ro.build"* ]]; then
      echo "Unable to communicate with robot. The key may be invalid, the bot may not be unlocked, or this device and the robot are not on the same network."
      exit 0
   fi
   ssh -i ${keyPath} root@${botAddress} "mount -o rw,remount / && systemctl stop vic-cloud && mv /anki/data/assets/cozmo_resources/config/server_config.json /anki/data/assets/cozmo_resources/config/server_config.json.bak"
   scp -O -i ${keyPath} ./vector-cloud/build/vic-cloud root@${botAddress}:/anki/bin/
   scp -O -i ${keyPath} ./vector-cloud/weather_weathercompany.json root@${botAddress}:/anki/data/assets/cozmo_resources/config/engine/behaviorComponent/weather/weatherResponseMaps/
   scp -O -i ${keyPath} ./certs/server_config.json root@${botAddress}:/anki/data/assets/cozmo_resources/config/
   scp -O -i ${keyPath} ./certs/cert.crt root@${botAddress}:/data/data/customCaCert.crt
   ssh -i ${keyPath} root@${botAddress} "chmod +rwx /anki/data/assets/cozmo_resources/config/server_config.json /anki/bin/vic-cloud /data/data/customCaCert.crt && systemctl start vic-cloud"
   rm -f /tmp/sshTest
   echo
   echo "Everything has been copied to the bot! While you don't need to reboot Vector for voice commands to work with your custom server, you will need to reboot Vector for the weather command to work correctly."
   echo
   echo "Everything is now setup! You should be ready to run chipper. sudo ./chipper/start.sh"
   echo
}

function setupSystemd() {
   if [[ ${TARGET} == "macos" ]]; then
      echo "This cannot be done on macOS."
      exit 1
   fi
   echo "[Unit]" > wire-pod.service
   echo "Description=Wire Escape Pod (coqui)" >> wire-pod.service
   echo >> wire-pod.service
   echo "[Service]" >> wire-pod.service
   echo "Type=simple" >> wire-pod.service
   echo "WorkingDirectory=$(readlink -f ./chipper)" >> wire-pod.service
   echo "ExecStart=$(readlink -f ./chipper/start.sh)" >> wire-pod.service
   echo >> wire-pod.service
   echo "[Install]" >> wire-pod.service
   echo "WantedBy=multi-user.target" >> wire-pod.service
   cat wire-pod.service
   echo
   echo "wire-pod.service created, building chipper..."
   cd chipper
         export CGO_LDFLAGS="-L$HOME/.coqui/"
      export CGO_CXXFLAGS="-I$HOME/.coqui/"
      export LD_LIBRARY_PATH="$HOME/.coqui/:$LD_LIBRARY_PATH"
   /usr/local/go/bin/go build cmd/main.go
   mv main chipper
   echo
   echo "./chipper/chipper has been built!"
   cd ..
   mv wire-pod.service /lib/systemd/system/
   systemctl daemon-reload
   systemctl enable wire-pod
   echo
   echo "systemd service has been installed and enabled! The service is called wire-pod.service"
   echo
   echo "To start the service, run: 'systemctl start wire-pod'"
   echo "Then, to see logs, run 'journalctl -fe | grep start.sh'"
}

function disableSystemd() {
   if [[ ${TARGET} == "macos" ]]; then
      echo "This cannot be done on macOS."
      exit 1
   fi
   echo
   echo "Disabling wire-pod.service"
   systemctl stop wire-pod.service
   systemctl disable wire-pod.service
   rm -f /lib/systemd/system/wire-pod.service
   systemctl daemon-reload
   echo
   echo "wire-pod.service has been removed and disabled."
}

function firstPrompt() {
   read -p "Enter a number (1): " yn
   case $yn in
      "1" ) echo; getPackages; getSTT; generateCerts; buildChipper; makeSource; echo "Everything is done! To copy everything needed to your bot, run this script like this:"; echo "Usage: sudo ./setup.sh scp <vector's ip> <path/to/ssh-key>"; echo "Example: sudo ./setup.sh scp 192.168.1.150 /home/wire/id_rsa_Vector-R2D2"; echo; echo "If your Vector is on Wire's custom software or you have an old dev build, you can run this command without an SSH key:"; echo "Example: sudo ./setup.sh scp 192.168.1.150"; echo ;;
      "2" ) echo; getPackages; buildCloud;;
      "3" ) echo; getPackages; buildChipper;;
      "4" ) echo; rm -f ./stt/completed; getSTT;;
      "5" ) echo; getPackages; generateCerts;;
      "6" ) echo; makeSource;;
      "" ) echo; getPackages; getSTT; generateCerts; buildChipper; makeSource; echo "Everything is done! To copy everything needed to your bot, run this script like this:"; echo "Usage: sudo ./setup.sh scp <vector's ip> <path/to/ssh-key>"; echo "Example: sudo ./setup.sh scp 192.168.1.150 /home/wire/id_rsa_Vector-R2D2"; echo; echo "If your Vector is on Wire's custom software or you have an old dev build, you can run this command without an SSH key:"; echo "Example: sudo ./setup.sh scp 192.168.1.150"; echo ;;
      * ) echo "Please answer with 1, 2, 3, 4, 5, 6, or just press enter with no input for 1."; firstPrompt;;
   esac
}

if [[ $1 == "scp" ]]; then
   botAddress=$2
   keyPath=$3
   scpToBot
   exit 0
fi

if [[ $1 == "daemon-enable" ]]; then
   setupSystemd
   exit 0
fi

if [[ $1 == "daemon-disable" ]]; then
   disableSystemd
   exit 0
fi

if [[ $1 == "-f" ]] && [[ $2 == "scp" ]]; then
   botAddress=$3
   keyPath=$4
   scpToBot
   exit 0
fi

echo "What would you like to do?"
echo "1: Full Setup (recommended) (builds chipper, gets STT stuff, generates certs, creates source.sh file, and creates server_config.json for your bot"
echo "2: Just build vic-cloud"
echo "3: Just build chipper"
echo "4: Just get STT stuff"
echo "5: Just generate certs"
echo "6: Just create source.sh file and config for bot (also for setting up weather API)"
echo "If you have done everything you have needed, run './setup.sh scp vectorip path/to/key' to copy the new vic-cloud and server config to Vector."
echo
firstPrompt
