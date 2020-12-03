#!/bin/bash

### CONFIG

FAILED_REGEX='FAILED_REGEX'		# regular expressiom to recognize requests as failed 
SUCCESS_FILE=$(pwd)/quick-success.txt	# output file to write all log lines with requests not matching failed filter
FAILURE_FILE=$(pwd)/quick-failed.txt	# output file to write all log lines with requests matching failed filter
MATCH_REGEX='FILTER_REGEX'			# regular expression by which log lines will be matched. Lines that won't much this exp. won't be taken into account
MATCH_FILE=$(pwd)/temp.tmp		# temporary file to save results, will be deleted after script finishes

###


# set working dir
if [ "$#" -gt 1 ]; then
    echo "Illegal number of parameters"
    exit 1
elif [[ "$#" -eq 1 ]]; then
	echo "using $1 as working directory"
	cd $1
	if [[ $? -ne 0 ]] ; then
		echo "failed to change working directory"
		exit 2
	fi
else
	echo "using $(pwd) as working directory"
fi


# unzip log files
gunzip ./* 2> /dev/null 


### set IFS

OLD_IFS=$IFS
IFS=$'\n'

###

# clear old result files
echo > $SUCCESS_FILE
echo > $FAILURE_FILE


### iterate over log files and check response code 
for logfile in $(ls ./ | grep ".*.log$") ; do
	echo "NOW ANALYZING FILE $logfile"
	cat $logfile | grep $MATCH_REGEX >> $MATCH_FILE				# write all matching lines to matching requests file
	cat $MATCH_FILE | grep "$FAILED_REGEX" >> $FAILURE_FILE			# write requests with negative response to correspodnign file 
	diff --new-line-format="" --unchanged-line-format="" $MATCH_FILE $FAILURE_FILE >> $SUCCESS_FILE 		#write the difference between both files (successful only) to corresponding file
	rm $MATCH_FILE		#rm temporary matching filr file
done

###

# count success rate
correct=$(wc -l "$SUCCESS_FILE" | cut -d' ' -f1)
incorrect=$(wc -l "$FAILURE_FILE" | cut -d' ' -f1)


# print results
echo -e "CHECKING FILES DONE\n"
echo "CORRECT REQUESTS: $correct"
echo "INCORRECT REQUESTS: $incorrect"
echo "SUCCESS RATE: $(echo "scale=4;(($correct/($incorrect + $correct)*100))" | bc) %" 

# set IFS to old value
IFS=$OLD_IFS
