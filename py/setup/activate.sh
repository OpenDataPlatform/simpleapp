#!/bin/bash


MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[  -f /etc/redhat-release ]]
then
	# shellcheck disable=SC1090
	source "${MYDIR}"/../venv_rhel/bin/activate
	PS1='[simpleapp.py] \h:\W \u\$ '
elif [[  -f /etc/os-release ]]
then
  . /etc/os-release
  if [[ "x$NAME" == "xUbuntu" ]]
  then
    echo "On Ubuntu system"
  	source "${MYDIR}"/../venv/bin/activate
	  PS1='[simpleapp.py] \h:\W \u\$ '
  else
    echo
    echo "Not on a RHEL,Centos, Ubuntu or MacOs system. Exiting!"
    # shellcheck disable=SC2034
    read a
    exit 1
  fi
elif [[ "$OSTYPE" == "darwin"* ]]
then
	# shellcheck disable=SC1090
	source "${MYDIR}"/../venv/bin/activate
	PS1='[simpleapp.py] \h:\W \u\$ '
else
	echo
	echo "Not on a RHEL or Centos or MacOs system. Exiting!"
	# shellcheck disable=SC2034
	read a
	exit 1
fi


