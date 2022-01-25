#! /bin/bash
#
# gccqs - GNU CLI CW QSO Simulator, version 1.0 beta
# Copyright (C) 2022, Ihor P. Sokorchuk <ur3lcm@gmail.com>
# License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
# This is free software; you are free to change and redistribute it.
# There is NO WARRANTY, to the extent permitted by law.

declare -xu dxCall='' myCall='' sendCall=''
declare -xi recvRst=599 dxWpm=14 dxTone=800 dxVolume=70
declare -xi sendRst=599 myWpm=14 myTone=800 myVolume=50

declare -r configDir="$HOME/.gccqs"
declare -r configFile="$configDir/gccqs.conf"

function showHelp() {
  echo '
gccqs - GNU CLI CW QSO Simulator, version 1.0 beta

Copyright (C) 2022, Ihor P. Sokorchuk <ur3lcm@gmail.com>
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software; you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

You must have the following utilities installed on your computer:
GNU bash, version 4.4.20   <https://www.gnu.org/software/bash/>
unixcw (cw), version 3.5.1 <https://github.com/g4z/unixcw>
                           <https://sourceforge.net/projects/unixcw/>
'
}

function exitProgram() {
  # [ -n "$cwPid" ] &&  kill "$cwPid" 2>/dev/null
  killall -q cw 2>/dev/null
  # killall -q play 2>/dev/null
  exit
}
trap "exitProgram" EXIT

function echoInfo() {
  echo 'Type command (c,q,?,a,t) or Q for Quit'
}

declare -r str1='1234567890QWERTYUIOPASDFGHJKLZXCVBNM'
declare -r str2='QWERTYUIOPASDFGHJKLZXCVBNM'
declare -r str3='1234567890'

function setNewDxInfo() {
  dxCall='R' 
  # No Pirates Allowed!
  callRegex='^R|^U[A-I]|^D[0-1]'
  while [[ "$dxCall" =~ $callRegex ]]; do
    dxCall="\
${str1:$((RANDOM % 36)):$((RANDOM)) % 2}\
${str2:$((RANDOM % 26)):1}\
${str3:$((RANDOM % 10)):1}\
${str3:$((RANDOM % 10)):$((RANDOM)) % 2}\
${str3:$((RANDOM % 10)):$((RANDOM)) % 2}\
${str1:$((RANDOM % 36)):$((RANDOM)) % 2}\
${str2:$((RANDOM % 26)):1}"
  done

  recvRst="5$((5 + (RANDOM % 4)))9"
  dxWpm="$((minDxWpm + (RANDOM % (maxDxWpm - minDxWpm))))"
  dxTone="$((minDxTone + (RANDOM % (maxDxTone - minDxTone))))"
  dxVolume="$((minDxVolume + (RANDOM % (maxDxVolume-minDxVolume))))"
}

function receiveDxCall() { ###
  echo "DE $dxCall [AR]"\
  | cw -em -w $dxWpm -t $dxTone -v $dxVolume
}

function receiveDxRaport() { ###
  case $(($RANDOM % 3)) in
    0) string="R R DE $dxCall UR ${recvRst//9/N} [AR]" ;;
    1) string="CFM DE $dxCall UR ${recvRst} [AR]" ;;
    *) string="QSL DE $dxCall UR ${recvRst//9/N} [AR]" ;;
  esac
  echo "$string"\
  | cw -em -w $dxWpm -t $dxTone -v $dxVolume
}

function sendCq() {
  echo "CQ CQ DE $1 [AR] K"\
  | cw -w $myWpm -t $myTone -v $myVolume
}

function sendQrz() {
  echo "QRZ? DE $1 [AR]"\
  | cw -w $myWpm -t $myTone -v $myVolume
}

function sendAgn() {
  echo "AGN [AR]"\
  | cw -w $myWpm -t $myTone -v $myVolume
}

function sendQslTu() {
  echo "QSL TU [SK]"\
  | cw -w $myWpm -t $myTone -v $myVolume
}

function doQso() {
  # doQSO myCall dxCall sendRst
  read -p 'DXCALL RST >> ' -ei "${2^^} ${3}" sendCall sendRst
  if (((sendRst < 333) || (sendRst > 599))); then sendRst=599; fi
  echo "DX CALL: $sendCall  DX RST: $sendRst"
  echo "$sendCall DE $1 UR ${sendRst//9/N} [AR]"\
  | cw -w $myWpm -t $myTone -v $myVolume
}


# MAIN()

regex='-h|--help'
if [[ "$1" =~ $regex ]]; then
  showHelp
  exit
fi

if [ ! -f "$configFile" ]; then

  mkdir -p "$configDir" || exit

  myCall=''
  callRegex=".{1,2}[0-9].+[A-Z]+"
  until [[ "$myCall" =~ $callRegex ]]; do
    read -p 'Your Call > ' myCall
  done

  myWpm=0
  while (((myWpm < 4) || (myWpm > 60))); do
    read -ei '14' -p 'Your WPM [4-60] > ' myWpm
  done

  myTone=0
  while (((myTone < 50) || (myTone > 4000))); do
    read -ei '800' -p 'Your Tone [0-4000] > ' myTone
  done

  myVolume=0
  while (((myVolume < 1) || (myVolume > 100))); do
    read -ei '50' -p 'Your Volume [0-100] > ' myVolume
  done

  minDxWpm=0
  while (((minDxWpm < 4) || (minDxWpm > 60))); do
    read -ei '12' -p 'Min DX WPM [4-60] > ' minDxWpm
  done

  maxDxWpm=0
  while (((maxDxWpm < minDxWpm) || (maxDxWpm > 60))); do
    read -ei '20' -p 'Max DX WPM [4-60] > ' maxDxWpm
  done

  minDxTone=0
  while (((minDxTone < 50) || (minDxTone > 4000))); do
    read -ei '300' -p 'Min DX Tone [0-4000] > ' minDxTone
  done

  maxDxTone=0
  while (((maxDxTone < minDxTone) || (maxDxTone > 4000))); do
    read -ei '1200' -p 'Max DX Tone [0-4000] > ' maxDxTone
  done


  minDxVolume=0
  while (((minDxVolume < 1) || (minDxVolume > 100))); do
    read -ei '1' -p 'Min DX Volume [0-100] > ' minDxVolume
  done

  maxDxVolume=0
  while (((maxDxVolume < minDxVolume) || (maxDxVolume > 100))); do
    read -ei '80' -p 'Max DX Volume [0-100] > ' maxDxVolume
  done

 {
   echo "myCall=${myCall:-NOCALL}"
   echo '#'
   echo "myWpm=${myWpm:-14}"
   echo "myTone=${myTone:-800}"
   echo "myVolume=${myVolume:-50}"
   echo '#'
   echo "minDxWpm=${minDxWpm:-12}"
   echo "maxDxWpm=${maxDxWpm:-20}"
   echo '#'
   echo "minDxTone=${minDxTone:-300}"
   echo "maxDxTone=${maxDxTone:-1200}"
   echo '#'
   echo "minDxVolume=${minDxVolume:-1}"
   echo "maxDxVolume=${maxDxVolume:-80}"
 } > "$configFile"

fi

source "$configFile"

echo 'gccqs - GNU CLI CW QSO Simulator'
echo '======================================'
echo "My Call:   $myCall"

echo "My WPM:    $myWpm PARIS"
echo "DX WPM:    ${minDxWpm}..${maxDxWpm} PARIS"

echo "Tone:      $myTone Hz"
echo "DX Tone:   ${minDxTone}..${maxDxTone} Hz"

echo "Volume:    $myVolume%"
echo "DX Volume: ${minDxVolume}..${maxDxVolume}%"

echo "Config File: $configFile"
echo '======================================'

setNewDxInfo
echoInfo

# (play -q -c 2 -r 48000 -e signed -L -b 32 -t raw -v 0.02 /dev/urandom) &
# noiceSoursePid=$!

PS3='Command or "DxCall RST"> '
select choice in 'CQ' 'QRZ?' 'AGN' 'TU'; do

  [ "$REPLY" == 'Q' ] && exit

  if   [ "$REPLY" == 'c' ]; then choice='CQ'
  elif [ "$REPLY" == 'q' ]; then choice='QRZ?'
  elif [ "$REPLY" == '?' ]; then choice='QRZ?'
  elif [ "$REPLY" == 'a' ]; then choice='AGN'
  elif [ "$REPLY" == 't' ]; then choice='TU'
  fi

  case "$choice" in
  CQ)
    sendCq $myCall && {
      setNewDxInfo
      (receiveDxCall) &
      cwPid="$!"
    }
    ;;
  QRZ?)
    sendQrz $myCall && {
      (receiveDxCall) &
      cwPid="$!"
    }
    ;;
  AGN)
    sendAgn $myCall && {
      (receiveDxCall) &
      cwPid="$!"
    }
    ;;
  TU)
    sendQslTu $myCall && {
      setNewDxInfo
      (sleep 5 && receiveDxCall) &
      cwPid="$!"
    }
    ;;
  *)
    IFS=' ' read -ra tmpArray <<< "$REPLY"

    sendCall="${tmpArray[0]:-dxCall}"

    tmpRst="${tmpArray[1]}"

    if (((tmpRst < 333) || (tmpRst > 599))); then
      sendRst=599
    else
      sendRst=$tmpRst
    fi

    callRegex=".{1,2}[0-9].+"
    if [[ "$sendCall" =~ $callRegex ]]; then

      doQso "$myCall" "$sendCall" "$sendRst"

      if [ "$dxCall" == "$sendCall" ]; then
        (receiveDxRaport) &
        cwPid="$!"
      else
        (receiveDxCall) &
        cwPid="$!"
      fi
    fi
    ;;
  esac

  echoInfo

done
