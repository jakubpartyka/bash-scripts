#!/bin/bash

###
# a simple backup script
###

# what to backup
source="/root /deployment /backup/archives"

# where to save the backup
dest="/backup/automatic"

# tmp filename
tmp="backup.tmp.tar.gz"

fn=$(date +%Y_%m_%d_%H_%M_%S)_backup.tar.gz

tar czvf $dest/$tmp $source

if [[ $? -ne 0 ]] ; then
	echo "failed to create backup, aborting"
fi

# remove previous backup files
rm "$dest"/*_backup.tar.gz
mv $dest/$tmp $dest/$fn

echo "backup created"
