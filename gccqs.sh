#! /bin/bash
#
# gccqs - GNU CLI CW QSO Simulator, version 1.2.0202-beta
# Copyright (C) 2022, Ihor P. Sokorchuk <ur3lcm@gmail.com>
# License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
# This is free software; you are free to change and redistribute it.
# There is NO WARRANTY, to the extent permitted by law.

declare -xu dxCall='' myCall='' sendCall='' qsoCall=''
declare -xi recvRst=599 dxWpm=14 dxTone=800 dxVolume=70
declare -xi sendRst=599 myWpm=14 myTone=800 myVolume=50
declare -i minDxWpm maxDxWpm minDxTone maxDxTone minDxVolume maxDxVolume

declare -r configDir="$HOME/.gccqs"
declare -r configFile="${configDir}/gccqs.conf"

function my::exitProgram() {
  ps -Af | grep cw
  [ -n "$!" ] && kill -KILL $! 2>/dev/null
  echo; echo "PID=$! CwPID=$cwPid"
  echo 'EXIT'
  exit
}

trap my::exitProgram EXIT

case "${LANG}" in
  uk_*) declare -r versionText=\
'gccqs - GNU CLI симулятор CW QSO, версія 1.2.0202-beta
Copyright (C) 2022, Ігор Сокорчук <ur3lcm@gmail.com>
Ліцензія GPLv3+: GNU GPL версії 3 або новішої <http://gnu.org/licenses/gpl.html>
Це безкоштовне програмне забезпечення, яке ви можете змінювати та поширювати.
Ця програма поширюється БЕЗ будь-яких передбачених законодавством ГАРАНТІЙ.

На вашому комп’ютері повинні бути встановлені такі утиліти:
GNU bash, версія 4.4.20 <https://www.gnu.org/software/bash/>
unixcw (cw), версія 3.5.1 <https://github.com/g4z/unixcw>
                          <https://sourceforge.net/projects/unixcw/>'

        declare -r helpText='Використовуйте: qccqs [КЛЮЧІ]
GNU CLI симулятор CW QSO

   -c, --configure  налаштувати та вийти
   -h, --help       показати цю довідку та вийти
   -v, --version    вивести інформацію про версію та вийти'
  ;;

  *)    declare -r versionText=\
'gccqs - GNU CLI CW QSO Simulator, version 1.2.0202-beta
Copyright (C) 2022, Ihor P. Sokorchuk <ur3lcm@gmail.com>
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software; you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

You must have the following utilities installed on your computer:
GNU bash, version 4.4.20   <https://www.gnu.org/software/bash/>
unixcw (cw), version 3.5.1 <https://github.com/g4z/unixcw>
                           <https://sourceforge.net/projects/unixcw/>'

        declare -r helpText='Usage: qccqs [OPTION]
GNU CLI CW QSO Simulator

  -c, --configure  configure and exit
  -h, --help       display this help and exit
  -v, --version    output version information and exit'
  ;;
esac

function my::showHelp() {
  echo "$helpText"
}

function my::showVersion() {
  echo "$versionText"
}

function my::changeConfiguration() {

  mkdir -p "${configDir}"

  [ -f "${configFile}" ] && source "${configFile}"

  myCall=${myCall:-'N0CALL'}
  regex=".{1,2}[0-9].+[A-Z]+"
  while :; do
    read -ei "${myCall}" -p 'Your Call >' myCall
    [[ "${myCall}" =~ ${regex} ]] && break
  done

  myWpm=${myWpm:-14}
  while :; do
    read -ei "${myWpm}" -p 'Your WPM [4-60] >' myWpm
    (((myWpm >= 4) && (myWpm <= 60))) && break
  done

  myTone=${myTone:-800}
  while :; do
    read -ei "${myTone}" -p 'Your Tone [0-4000] >' myTone
    (((myTone >= 50) && (myTone <= 4000))) && break
  done

  myVolume=${myVolume:-50}
  while :; do
    read -ei "${myVolume}" -p 'Your Volume [0-100] >' myVolume
    (((myVolume >= 1) && (myVolume <= 100))) && break
  done

  minDxWpm=${minDxWpm:-12}
  while :; do
    read -ei "${minDxWpm}" -p 'Min DX WPM [4-60] >' minDxWpm
    (((minDxWpm >= 4) && (minDxWpm <= 60))) && break
  done

  maxDxWpm=${maxDxWpm:-22}
  while :; do
    read -ei "${maxDxWpm}" -p 'Max DX WPM [4-60] >' maxDxWpm
    (((maxDxWpm >= minDxWpm) && (maxDxWpm <= 60))) && break
  done

  # CW Filter Bandwidth
  # Triangle / Rectangle

  minDxTone=${minDxTone:-300}
  while :; do
    read -ei "${minDxTone}" -p 'Min DX Tone [0-4000] >' minDxTone
    (((minDxTone >= 50) && (minDxTone <= 4000))) && break
  done

  maxDxTone=${maxDxTone:-1200}
  while :; do
    read -ei "${maxDxTone}" -p 'Max DX Tone [0-4000] >' maxDxTone
    (((maxDxTone >= minDxTone) && (maxDxTone <= 4000))) && break
  done

  minDxVolume=${minDxVolume:-1}
  while :; do
    read -ei "${minDxVolume}" -p 'Min DX Volume [0-100] >' minDxVolume
    (((minDxVolume >= 1) && (minDxVolume <= 100))) && break
  done

  maxDxVolume=${maxDxVolume:-100}
  while :; do
    read -ei "${maxDxVolume}" -p 'Max DX Volume [0-100] >' maxDxVolume
    (((maxDxVolume >= minDxVolume) && (maxDxVolume <= 100))) && break
  done

 {
   echo "myCall=${myCall}"
   echo '#'
   echo "myWpm=${myWpm}"
   echo "myTone=${myTone}"
   echo "myVolume=${myVolume}"
   echo '#'
   echo "minDxWpm=${minDxWpm}"
   echo "maxDxWpm=${maxDxWpm}"
   echo '#'
   echo "minDxTone=${minDxTone}"
   echo "maxDxTone=${maxDxTone}"
   echo '#'
   echo "minDxVolume=${minDxVolume}"
   echo "maxDxVolume=${maxDxVolume}"
 } > "${configFile}" &&  echo -e "\nOK Configuration saved\n"
}

function my::showConfiguration() {
  echo '======================================================'
  echo "My Call:   $myCall"
  echo "My WPM:    $myWpm PARIS"
  echo "My Tone:   $myTone Hz"
  echo "My Volume: $myVolume%"
  echo "DX WPM:    ${minDxWpm}..${maxDxWpm} PARIS"
  echo "DX Tone:   ${minDxTone}..${maxDxTone} Hz"
  echo "DX Volume: ${minDxVolume}..${maxDxVolume}%"
  echo "Config File: ${configFile}"
  echo '======================================================'
}

function my::echoInfo() {
  echo 'c) CQ; q,?) QRZ?; a) AGN; t) TU;'
  echo 'Type command: c,q,?,a,t or C for Config and Q for Quit'
}

declare -r alphaString='QWERTYUIOPASDFGHJKLZXCVBNM'
declare -r digitString='1234567890'
declare -r alnumString="${digitString}${alphaString}"

function my::setNewDxInfo() {
  dxCall='_'
  # No Pirates Allowed!
  regex='_|^R|^U[A-I0-9]|^D[0-1]'
  while [[ "${dxCall}" =~ ${regex} ]]; do
    dxCall="\
${alnumString:$((RANDOM % 36)):$((RANDOM)) % 2}\
${alphaString:$((RANDOM % 26)):1}\
${digitString:$((RANDOM % 10)):1}\
${digitString:$((RANDOM % 10)):$((RANDOM)) % 2}\
${digitString:$((RANDOM % 10)):$((RANDOM)) % 2}\
${alnumString:$((RANDOM % 36)):$((RANDOM)) % 2}\
${alphaString:$((RANDOM % 26)):1}"
  done

  recvRst="5$((5 + (RANDOM % 4)))9"
  dxWpm="$((minDxWpm + (RANDOM % (maxDxWpm - minDxWpm))))"
  dxTone="$((minDxTone + (RANDOM % (maxDxTone - minDxTone))))"
  dxVolume="$((minDxVolume + (RANDOM % (maxDxVolume-minDxVolume))))"
  echo "TONE=$dxTone"
}

function my::sendCwText() {
  echo -n '>>> '
  echo "$@" | cw -m -w ${myWpm} -t ${myTone} -v ${myVolume}
}

function my::sendDxCwText() {
  echo "$@" | cw -em -w ${dxWpm} -t ${dxTone} -v ${dxVolume}
}

function my::soundDxCall() { ###
  my::sendDxCwText "DE ${dxCall} [AR]"
}

function my::soundDxRaport() { ###
  case $(($RANDOM % 3)) in
    0) string="R R DE ${dxCall} UR ${recvRst//9/N} [AR]" ;;
    1) string="CFM DE ${dxCall} UR ${recvRst} [AR]" ;;
    *) string="QSL DE ${dxCall} UR ${recvRst//9/N} [AR]" ;;
  esac
  my::sendDxCwText "${string}"
}

function my::sendCq() {
  my::sendCwText "CQ CQ DE $1 [AR] K" ## Echo ???
}

function my::sendQrz() {
  my::sendCwText "QRZ? DE $1 [AR]"
}

function my::sendAgn() {
  my::sendCwText "AGN [AR]"
}

function my::sendQuestionMark() {
  my::sendCwText '?'
}

function my::sendQslTu() {
  my::sendCwText "QSL TU [VA]"
}

function my::makeQso() {
  # makeQso myCall dxCall sendRst
  #  read -p 'DXCALL RST >>> ' -ei "${2^^} ${3}" sendCall sendRst
  if (((sendRst < 333) || (sendRst > 599))); then sendRst=599; fi
  #  echo "DX CALL: ${sendCall}  DX RST: ${sendRst}"
  my::sendCwText "${sendCall} DE $1 UR ${sendRst//9/N} [AR]"
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

# (play -q -c 2 -r 48000 -e signed -L -b 32 -t raw -v 0.02 /dev/urandom) &
# noiceSoursePid=$!

while :; do

  my::echoInfo

  read -ei "$qsoCall" -p 'Command or "DxCall RST" >' userCommand userOption etc

  case "${userCommand}" in
  c) # CQ
    my::sendCq ${myCall} && {
      my::setNewDxInfo
      (my::soundDxCall) &
      cwPid="$!"
    }
    ;;
  q) # QRZ_QUESTION
    my::sendQrz ${myCall} && {
      (my::soundDxCall) &
      cwPid="$!"
    }
    ;;
  a) # AGN
    my::sendAgn ${myCall} && {
      (my::soundDxCall) &
      cwPid="$!"
    }
    ;;
  t) # TU
    my::sendQslTu ${myCall} && {
      my::setNewDxInfo
      (sleep $(((RANDOM % 3) + 1)) && my::soundDxCall) &
      cwPid="$!"
    }
    qsoCall=''
    ;;
  C) # CONFIG
    echo; echo "CHANGE CONFIGURATION"; echo
    my::changeConfiguration
    ;;
  \?) # QUESTION_MARK
    my::sendQuestionMark ${myCall} && {
      (my::soundDxCall) &
      cwPid="$!"
    }
    ;;
  Q) # EXIT
    exit
    ;;
  ??*)
    if [[ "${userCommand}" =~ \? ]]; then
      # is a call question mark
      qsoCall="${userCommand%?}"
      sendCall="${userCommand}"
      my::sendCwText "${sendCall} PSE"
      [[ ${dxCall} =~ ${sendCall//\?/.+} ]] && {
        (my::soundDxCall) &
        cwPid="$!"
      }
    elif [[ "${userOption}" =~ \? ]]; then
      # is a option question mark
      qsoCall="${userCommand}"
      sendCall="${userCommand}"
      my::sendCwText "${sendCall} \?"
      [[ ${dxCall} =~ ${sendCall} ]] && {
        (my::soundDxCall) &
        cwPid="$!"
      }
    elif [[ "${userCommand}" =~ .{1,2}[0-9].+ ]]; then
      qsoCall=''
      sendCall="${userCommand}" # is a call sign
      sendRst="${userOption}"
      (((sendRst < 333) || (sendRst > 599))) && sendRst=599
      my::makeQso "${myCall}" "${sendCall}" "${sendRst}"
      if [ "${sendCall}" == "${dxCall}" ]; then # sent correct call sign
        (my::soundDxRaport) &
        cwPid="$!"
      else # sent incorrect call sign
        (my::soundDxCall) &
        cwPid="$!"
      fi
    fi
    ;;
  esac
done

# EOF

#Usage: dfdffgfhghgh [OPTIONS] filename
#
#Generic Options
#  -h, --help                              Print this help and exit.
#      --version                           Print program version and exit.
#      --print-config                      Print info about options selected
#                                          during compilation and exit.

