#! /bin/bash
#
# gccqs - GNU CLI CW QSO Simulator, version 1.0.0127-beta
# Copyright (C) 2022, Ihor P. Sokorchuk <ur3lcm@gmail.com>
# License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
# This is free software; you are free to change and redistribute it.
# There is NO WARRANTY, to the extent permitted by law.

declare -xu dxCall='' myCall='' sendCall=''
declare -xi recvRst=599 dxWpm=14 dxTone=800 dxVolume=70
declare -xi sendRst=599 myWpm=14 myTone=800 myVolume=50
declare -i minDxWpm maxDxWpm minDxTone maxDxTone minDxVolume maxDxVolume

declare -r configDir="$HOME/.gccqs"
declare -r configFile="${configDir}/gccqs.conf"

declare -r ukrainianShowVersionText=\
'gccqs - GNU CLI симулятор CW QSO, версія 1.0.0127-beta
Copyright (C) 2022, Ігор Сокорчук <ur3lcm@gmail.com>
Ліцензія GPLv3+: GNU GPL версії 3 або новішої <http://gnu.org/licenses/gpl.html>
Це безкоштовне програмне забезпечення, яке ви можете змінювати та поширювати.
Це програма поширюється БЕЗ будь-яких передбачених законодавством ГАРАНТІЙ.

На вашому комп’ютері повинні бути встановлені такі утиліти:
GNU bash, версія 4.4.20 <https://www.gnu.org/software/bash/>
unixcw (cw), версія 3.5.1 <https://github.com/g4z/unixcw>
                          <https://sourceforge.net/projects/unixcw/>'

declare -r englishShowVersionText=\
'gccqs - GNU CLI CW QSO Simulator, version 1.0.0127-beta
Copyright (C) 2022, Ihor P. Sokorchuk <ur3lcm@gmail.com>
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software; you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

You must have the following utilities installed on your computer:
GNU bash, version 4.4.20   <https://www.gnu.org/software/bash/>
unixcw (cw), version 3.5.1 <https://github.com/g4z/unixcw>
                           <https://sourceforge.net/projects/unixcw/>'

declare -r ukrainianShowHelpText='Використовуйте: qccqs [КЛЮЧІ]
GNU CLI симулятор CW QSO 

   -c, --configure  налаштувати та вийти
   -h, --help       показати цю довідку та вийти
   -v, --version    вивести інформацію про версію та вийти'

declare -r englishShowHelpText='Usage: qccqs [OPTION]
GNU CLI CW QSO Simulator

  -c, --configure  configure and exit
  -h, --help       display this help and exit
  -v, --version    output version information and exit'

function my::showHelp() {
  case "${LANG}" in
    uk_*) echo "$ukrainianShowHelpText" ;;
    *) echo "$englishShowHelpText" ;;
  esac
}

function my::showVersion() {
  case "${LANG}" in
    uk_*) echo "$ukrainianShowVersionText" ;;
    *) echo "$englishShowVersionText" ;;
  esac
}

function my::exitProgram() {
  # [ -n "${cwPid}" ] &&  kill "${cwPid}" 2>/dev/null
  killall -q cw 2>/dev/null
  # killall -q play 2>/dev/null
  exit
}

trap my::exitProgram EXIT

function my::changeConfiguration() {

  mkdir -p "${configDir}"

  [ -f "${configFile}" ] && source "${configFile}"

  myCall=${myCall:-''}
  regex=".{1,2}[0-9].+[A-Z]+"
  while :; do
    read -ei "${myCall}" -p 'Your Call > ' myCall
    [[ "${myCall}" =~ ${regex} ]] && break
  done

  myWpm=${myWpm:-14}
  while :; do
    read -ei "${myWpm}" -p 'Your WPM [4-60] > ' myWpm
    (((myWpm >= 4) && (myWpm <= 60))) && break
  done

  myTone=${myTone:-800}
  while :; do
    read -ei "${myTone}" -p 'Your Tone [0-4000] > ' myTone
    (((myTone >= 50) && (myTone <= 4000))) && break
  done

  myVolume=${myVolume:-50}
  while :; do
    read -ei "${myVolume}" -p 'Your Volume [0-100] > ' myVolume
    (((myVolume >= 1) && (myVolume <= 100))) && break
  done

  minDxWpm=${minDxWpm:-12}
  while :; do
    read -ei "${minDxWpm}" -p 'Min DX WPM [4-60] > ' minDxWpm
    (((minDxWpm >= 4) && (minDxWpm <= 60))) && break
  done

  maxDxWpm=${maxDxWpm:-20}
  while :; do
    read -ei "${maxDxWpm}" -p 'Max DX WPM [4-60] > ' maxDxWpm
    (((maxDxWpm >= minDxWpm) && (maxDxWpm <= 60))) && break
  done

  # CW Filter Bandwidth
  # Triangle / Rectangle

  minDxTone=${minDxTone:-300}
  while :; do
    read -ei "${minDxTone}" -p 'Min DX Tone [0-4000] > ' minDxTone
    (((minDxTone >= 50) && (minDxTone <= 4000))) && break
  done

  maxDxTone=${maxDxTone:-300}
  while :; do
    read -ei "${maxDxTone}" -p 'Max DX Tone [0-4000] > ' maxDxTone
    (((maxDxTone >= minDxTone) && (maxDxTone <= 4000))) && break
  done

  minDxVolume=${minDxVolume:-1}
  while :; do
    read -ei "${minDxVolume}" -p 'Min DX Volume [0-100] > ' minDxVolume
    (((minDxVolume >= 1) && (minDxVolume <= 100))) && break
  done

  maxDxVolume=${maxDxVolume:-1}
  while :; do
    read -ei "${maxDxVolume}" -p 'Max DX Volume [0-100] > ' maxDxVolume
    (((maxDxVolume >= minDxVolume) && (maxDxVolume <= 100))) && break
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
 } > "${configFile}"

}

function my::showConfiguration() {
  echo '======================================'
  echo "My Call:   $myCall"
  echo "My WPM:    $myWpm PARIS"
  echo "My Tone:   $myTone Hz"
  echo "My Volume: $myVolume%"
  echo "DX WPM:    ${minDxWpm}..${maxDxWpm} PARIS"
  echo "DX Tone:   ${minDxTone}..${maxDxTone} Hz"
  echo "DX Volume: ${minDxVolume}..${maxDxVolume}%"
  echo "Config File: ${configFile}"
  echo '======================================'
}

function my::echoInfo() {
  echo 'Type command (c,q,?,a,t) or Q for Quit'
}

declare -r alphaString='QWERTYUIOPASDFGHJKLZXCVBNM'
declare -r digitString='1234567890'
declare -r alnumString="${digitString}${alphaString}"

function my::setNewDxInfo() {
  dxCall='R' 
  # No Pirates Allowed!
  regex='^R|^U[A-I]|^D[0-1]'
  while [[ "${dxCall}" =~ ${regex} ]]; do
    dxCall="\
${alnumString:$((RANDOM % 36)):$((RANDOM)) % 2}\
${alnumString:$((RANDOM % 26)):1}\
${digitString:$((RANDOM % 10)):1}\
${digitString:$((RANDOM % 10)):$((RANDOM)) % 2}\
${digitString:$((RANDOM % 10)):$((RANDOM)) % 2}\
${alnumString:$((RANDOM % 36)):$((RANDOM)) % 2}\
${alnumString:$((RANDOM % 26)):1}"
  done

  recvRst="5$((5 + (RANDOM % 4)))9"
  dxWpm="$((minDxWpm + (RANDOM % (maxDxWpm - minDxWpm))))"
  dxTone="$((minDxTone + (RANDOM % (maxDxTone - minDxTone))))"
  dxVolume="$((minDxVolume + (RANDOM % (maxDxVolume-minDxVolume))))"
}

function my::receiveDxCall() { ###
  echo "DE ${dxCall} [AR]"\
  | cw -em -w ${dxWpm} -t ${dxTone} -v ${dxVolume}
}

function my::receiveDxRaport() { ###
  case $(($RANDOM % 3)) in
    0) string="R R DE ${dxCall} UR ${recvRst//9/N} [AR]" ;;
    1) string="CFM DE ${dxCall} UR ${recvRst} [AR]" ;;
    *) string="QSL DE ${dxCall} UR ${recvRst//9/N} [AR]" ;;
  esac
  echo "${string}"\
  | cw -em -w ${dxWpm} -t ${dxTone} -v ${dxVolume}
}

function my::sendCq() {
  echo "CQ CQ DE $1 [AR] K"\
  | cw -w ${myWpm} -t ${myTone} -v ${myVolume}
}

function my::sendQrz() {
  echo "QRZ? DE $1 [AR]"\
  | cw -w ${myWpm} -t ${myTone} -v ${myVolume}
}

function my::sendAgn() {
  echo "AGN [AR]"\
  | cw -w ${myWpm} -t ${myTone} -v ${myVolume}
}

function my::sendQuestionMark() {
  echo '?'\
  | cw -w ${myWpm} -t ${myTone} -v ${myVolume}
}

function my::sendQslTu() {
  echo "QSL TU [SK]"\
  | cw -w ${myWpm} -t ${myTone} -v ${myVolume}
}

function my::doQso() {
  # doQSO myCall dxCall sendRst
  read -p 'DXCALL RST >> ' -ei "${2^^} ${3}" sendCall sendRst
  if (((sendRst < 333) || (sendRst > 599))); then sendRst=599; fi
  echo "DX CALL: ${sendCall}  DX RST: ${sendRst}"
  echo "${sendCall} DE $1 UR ${sendRst//9/N} [AR]"\
  | cw -w ${myWpm} -t ${myTone} -v ${myVolume}
}

# MAIN()

while [ $# -gt 0 ]; do
  case "$1" in
    -c|--config)
      [ -f "${configFile}" ] && source "${configFile}"
      my::changeConfiguration
      my::showConfiguration
      exit
      ;;
    -v|--version) my::showVersion; exit ;;
    -h|--help) my::showHelp; exit ;;
  esac
  shift
done

echo 'gccqs - GNU CLI CW QSO Simulator'
echo 'Copyright (C) 2022, Ihor P. Sokorchuk <ur3lcm@gmail.com>'

if [ ! -f "${configFile}" ]; then
  my::changeConfiguration
fi

source "${configFile}"
my::showConfiguration

my::setNewDxInfo
my::echoInfo

# (play -q -c 2 -r 48000 -e signed -L -b 32 -t raw -v 0.02 /dev/urandom) &
# noiceSoursePid=$!

PS3='Command or "DxCall RST"> '
select userChoice in 'CQ' 'QRZ?' 'AGN' 'TU'; do

  read userCommand userOption <<<"${REPLY}"

  sendCall="${userCommand}"

  [[ "${userOption}" == '?' ]] && userOption='question'

  sendRst="${userOption}"
  (((sendRst < 333) || (sendRst > 599))) && sendRst=599

  if   [ "${userCommand}" == 'Q' ]; then exit
  elif [ "${userCommand}" == 'c' ]; then userChoice='CQ'
  elif [ "${userCommand}" == 'q' ]; then userChoice='QRZ?'
  elif [ "${userCommand}" == '?' ]; then userChoice='QRZ?'
  elif [ "${userCommand}" == 'a' ]; then userChoice='AGN'
  elif [ "${userCommand}" == 't' ]; then userChoice='TU'
  elif [ "${userOption}" == 'question' ];  then userChoice='question'
  fi

  case "${userChoice}" in
  CQ)
    my::sendCq ${myCall} && {
      my::setNewDxInfo
      (my::receiveDxCall) &
      cwPid="$!"
    }
    ;;
  QRZ?)
    my::sendQrz ${myCall} && {
      (my::receiveDxCall) &
      cwPid="$!"
    }
    ;;
  AGN)
    my::sendAgn ${myCall} && {
      (my::receiveDxCall) &
      cwPid="$!"
    }
    ;;
  TU)
    my::sendQslTu ${myCall} && {
      my::setNewDxInfo
      (sleep $(((RANDOM % 3) + 1)) && my::receiveDxCall) &
      cwPid="$!"
    }
    ;;
  question)
    my::sendQuestionMark ${myCall} && {
      (my::receiveDxCall) &
      cwPid="$!"
    }
    ;;
  *)
    # read sendCall sendRst <<<"$REPLY"

    regex=".{1,2}[0-9].+"
    if [[ "${sendCall}" =~ ${regex} ]]; then

      my::doQso "${myCall}" "${sendCall}" "${sendRst}"

      if [ "${dxCall}" == "${sendCall}" ]; then
        (my::receiveDxRaport) &
        cwPid="$!"
      else
        (my::receiveDxCall) &
        cwPid="$!"
      fi
    fi
    ;;
  esac

  my::echoInfo

done
