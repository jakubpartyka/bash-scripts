#!/bin/bash

# THIS SCRIPT ADDS IP ADDRESSES TO /etc/hosts.deny FILES CHECKING FOR DUPLICATES

TMP_FILE="./deny.tmp"
TMP_FILE_2="./deny_2.tmp"
PREFIX="sshd: "

# check number of given arguments 
if [[ $# -lt 1 ]] ; then
	echo "please provide an input file"
	exit 1
fi

# check if all files were specifed correctly 
for file in $@ ; do
	if [[ ! -f $file ]] ; then
		echo "$file is not a valid file"
		exit 2
	fi
done

# put IPs to temporary file
for file in $@ ; do
	cat "$file" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" >> "$TMP_FILE"
done

# sort and pick unique addresses
cat "$TMP_FILE" | sort -u > "$TMP_FILE_2"
cat "$TMP_FILE_2" > "$TMP_FILE"
rm "$TMP_FILE_2"


added=0
duplicates=0

for line in $(cat $TMP_FILE) ; do
	grep -q $line /etc/hosts.deny
	
	if [[ $? -ne 0 ]] ; then
		echo "$PREFIX$line" >> /etc/hosts.deny
		echo "$line added"
		((added++))
	else
		echo "$line is a duplicate"
		((duplicates++))
	fi
done

# delete TMP_FILE file
rm "$TMP_FILE"

echo "$added addresses added, $duplicates skipped"
