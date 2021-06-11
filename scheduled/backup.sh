#!/bin/bash

###
# a simple backup script
###

# what to backup
source="/root /deployment /backup/archives"

# where to save the backup
dest="/backup/automatic"

fn=$(date +%Y.%m.%d)_backup.tar.gz

tar czvf $dest/$fn $source

echo "backup created"
