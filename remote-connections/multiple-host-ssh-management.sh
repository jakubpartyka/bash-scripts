#!/bin/bash

# SERVER LIST
declare -A serv
serv=( ["1"]="1.2.3.4" ["2"]="5.6.7.8" ["3"]="9.10.11.12")


target=$1
if [[ $# -ne 1 ]] ; then 
	echo "choose target server:"
	
	for id in "${!serv[@]}" ; do
		echo "[$id] - "${serv[$id]}
	done
	read target
fi


# check if file exists
keyfile="/home/jakubpar/.ssh/server_$target"
echo "looking for ssh key: $keyfile"
if [[ ! -f $keyfile ]] ; then
	echo "couldn't find matching ssh key. Aborting..."
	exit 2
fi


# connect to server
echo "connecting to server [$target] : "${serv[$target]}
echo "#################"

ssh -i "/home/jakubpar/.ssh/server_$target" root@${serv[$target]}
