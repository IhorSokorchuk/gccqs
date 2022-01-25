#! /bin/bash
#
# gccqs - GNU CLI CW QSO Simulator, version 1.0
# Copyright (C) 2022, Ihor P. Sokorchuk <ur3lcm@gmail.com>
# License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
# This is free software; you are free to change and redistribute it.
# There is NO WARRANTY, to the extent permitted by law.

declare -xu dxCall='' myCall='' sendCall=''
declare -xi recvRst=599 dxWpm=14 dxTone=800 dxVolume=70
declare -xi sendRst=599 myWpm=14 myTone=800 myVolume=50

function showHelp() {
  echo '
gccqs - GNU CLI CW QSO Simulator, version 1.0

Copyright (C) 2022, Ihor P. Sokorchuk <ur3lcm@gmail.com>
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software; you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

You must have the following utilities installed on your computer:
GNU bash, version 4.4.20
cw version 3.5.1
'
}

function exitProgram() {
  # [ -n "$cwPid" ] &&  kill "$cwPid" 2>/dev/null
  killall -q cw 2>/dev/null 
  exit
}
trap "exitProgram" EXIT

function echoInfo() {
  echo 'Type command (c,q,?,a,t) or Q for Quit'
}

str1='1234567890QWERTYUIOPASDFGHJKLZXCVBNM'
str2='QWERTYUIOPASDFGHJKLZXCVBNM'
str3='1234567890'

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
  dxWpm="$((12 + (RANDOM % 8)))"
  dxTone="$((300 + (RANDOM % 800)))"
  dxVolume="$((10 + (RANDOM % 50)))"
}

function receiveDxCall() { ### ????
  echo "DE $dxCall [AR]"\
  | cw -em -w $dxWpm -t $dxTone -v $dxVolume
}

function receiveDxRaport() { ### ????
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

if [ ! -f gccqs.conf ]; then

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

 {
   echo "myCall=${myCall:-NOCALL}"
   echo "myWpm=${myWpm:-12}"
   echo "myTone=${myTone:-800}"
   echo "myVolume=${myVolume:-50}"
 } > gccqs.conf

fi

source gccqs.conf

echo 'gccqs - CLI CW QSO Simulator'
echo '======================================'
echo "Call:   $myCall"
echo "WPM:    $myWpm"
echo "Tone:   $myTone"
echo "Volume: $myVolume"
echo '======================================'

setNewDxInfo
echoInfo

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
