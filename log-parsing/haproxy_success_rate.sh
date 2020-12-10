#!/bin/bash

###
# Author: Jakub Partyka
# Purpose: Iterates over haproxy logs. Counts rate of responses matching regex in selected time range
#
# accepted log format:
# Nov 28 00:00:00 [info] haproxy[17]: 192.168.144.0:33534 [27/Nov/2020:23:59:59.761] component_name BACKEND/SERVER 0/0/108/128/239 200 2432 - - ---- 5/5/0/0/0 0/0 "POST /http/request/path"
#
###

### CONFIG ###
RATE_TIME_RANGE=2             #0 - SECOND / 1 - 10 SECONDS / 2 - MINUTE / 3 - 10 MINUTES / 4 - HOUR

OK_RESP_CODE_REGEX='^200$'		              # resp codes matching this regex will be marked as successful
MATCH_REGEX='INSERT_MATCH_REGEX+HERE'       # regular expression by which log lines will be matched. Lines that won't much this exp. won't be taken into account
OUTPUT_HTML=$(pwd)/success_rate.html
OUTPUT_FILE=$(pwd)/success_rate.txt     	  # output file to write timestamp-rate pair
TEMP_1=$(pwd)/temp1.tmp		                  # temporary file to save results, will be deleted after script finishes
TEMP_2=$(pwd)/temp2.tmp
###


# SET WORKING DIRECTORY
if [[ "$#" -gt 1 ]]; then
    echo "Illegal number of parameters"
    exit 1
elif [[ "$#" -eq 1 ]]; then
	echo "using $1 as working directory"
	cd "$1" || echo "failed to change working directory" ; exit
else
	echo "using $(pwd) as working directory"
fi


# UNZIP LOG FILES
gunzip ./* 2> /dev/null

# MERGE *.log FILES
cat ./*.log | grep $MATCH_REGEX | sort -u > "$TEMP_1"    # all requests matching general filter are stored here

# SET DATE
# shellcheck disable=SC2002
DATE=$(cat "$TEMP_1" | head -n1 | cut -d' ' -f7 | cut -c 2-12)

# SET CUT RANGE AND TIMESTAMP SUFFIX
if [[ $RATE_TIME_RANGE -eq 0 ]] ; then
  RATE="[1s]"
  CUT=8;
  SUFFIX=""
elif [[ $RATE_TIME_RANGE -eq 1 ]] ; then
  RATE="[10s]"
  CUT=7;
  SUFFIX="0"
elif [[ $RATE_TIME_RANGE -eq 2 ]]; then
  RATE="[1m]"
  CUT=5;
  SUFFIX=":00"
elif [[ $RATE_TIME_RANGE -eq 3 ]]; then
  RATE="[10m]"
  CUT=4;
  SUFFIX="0:00"
elif [[ $RATE_TIME_RANGE -eq 4 ]]; then
  RATE="[1h]"
  CUT=2;
  SUFFIX=":00:00"
else
  echo "INCORRECT RATE_TIME_RANGE SELECTED"
  exit 1;
fi

# PRINT CONFIGURATION
echo -e "\nanalyzing logs for $DATE with rate set to $RATE\n"

# shellcheck disable=SC2002
cat "$TEMP_1" | tr -s " " | grep STET | cut -d' ' -f3,11 | cut --output-delimiter=' ' -c1-"$CUT",10-13 | sort | uniq -c | tr -s " " | cut -d' ' -f2-4 > "$TEMP_2"


# SET IFS
OLD_IFS=$IFS
IFS=$'\n'

# CLEAR OUTPUT FILE
echo "TIMESTAMP STATUS NUMBER" > "$OUTPUT_FILE"


# PREPARE OUTPUT HTML FILE
echo "<html>
<head>
    <script type=\"text/javascript\" src=\"https://www.gstatic.com/charts/loader.js\"></script>
    <script type=\"text/javascript\">
        google.charts.load('current', {'packages':['corechart']});
        google.charts.setOnLoadCallback(drawChart);

        function drawChart() {
            var data = google.visualization.arrayToDataTable([
                ['Timestamp','Successful $RATE', 'Failed $RATE']" > "$OUTPUT_HTML"

### MAP CODES TO OK / KO
LAST_TS=0
LAST_TS_OK_CODE=0
LAST_TS_KO_CODE=0

LINE_COUNT=$(wc -l "$TEMP_2" | cut -d' ' -f1)
CUR_LINE=0


# shellcheck disable=SC2013
for line in $(cat "$TEMP_2") ; do
  # increase line counter
  ((CUR_LINE++))


  # shellcheck disable=SC2086
  CODE_COUNT=$(echo $line | cut -d' ' -f1)
  TS=$(echo "$line" | cut -d' ' -f2)
  CODE=$(echo "$line" | cut -d' ' -f3)

  echo -ne "\rCount in progress.Currently analyzing timestamp: $TS$SUFFIX"

  # HANDLE TIMESTAMP DUPLICATE
  if [[ "$TS" == "$LAST_TS" ]] ; then
    if [[ "$CODE" =~ $OK_RESP_CODE_REGEX ]] ; then
    CODE="OK"
    LAST_TS_OK_CODE=$((LAST_TS_OK_CODE + CODE_COUNT))
  else
    CODE="KO";
    LAST_TS_KO_CODE=$((LAST_TS_KO_CODE + CODE_COUNT))
    fi
    continue ;
  else
    ## current timestamp is different from old timestamp

    ## SKIP first entry
    if [[ $CUR_LINE -gt 1 ]] ; then
      echo "$LAST_TS$SUFFIX OK $LAST_TS_OK_CODE" >> "$OUTPUT_FILE"
      echo "$LAST_TS$SUFFIX KO $LAST_TS_KO_CODE" >> "$OUTPUT_FILE"
      echo -e ",\n['$LAST_TS$SUFFIX', $LAST_TS_OK_CODE,$LAST_TS_KO_CODE]" >> "$OUTPUT_HTML"
      LAST_TS_OK_CODE=0
      LAST_TS_KO_CODE=0
    fi
  fi


  #check CODE ; set last row values
  if [[ "$CODE" =~ $OK_RESP_CODE_REGEX ]] ; then
    CODE="OK"
    LAST_TS_OK_CODE=$CODE_COUNT
  else
    CODE="KO";
    LAST_TS_KO_CODE=$CODE_COUNT
  fi

  LAST_TS=$TS

  # PRINT LAST ROW
  if [[ $CUR_LINE -eq $LINE_COUNT ]] ; then
    echo "$LAST_TS$SUFFIX OK $LAST_TS_OK_CODE" >> "$OUTPUT_FILE"
    echo "$LAST_TS$SUFFIX KO $LAST_TS_KO_CODE" >> "$OUTPUT_FILE"
    echo -e ",\n['$LAST_TS$SUFFIX', $LAST_TS_OK_CODE,$LAST_TS_KO_CODE]" >> "$OUTPUT_HTML"
  fi

done

# CLOSE OUTPUT HTML FILE
echo "]);

            var options = {
                title: 'Requests $RATE on $DATE',
                // curveType: 'function',
                legend: { position: 'bottom' }
            };

            var chart = new google.visualization.LineChart(document.getElementById('curve_chart'));

            chart.draw(data, options);
        }
    </script>
</head>
<body>
<div id=\"curve_chart\" style=\"width: 100%; height: 100%\"></div>
</body>
</html>" >> "$OUTPUT_HTML"


# UNSET IFS
IFS=$OLD_IFS

# DELETE .tmp FILES
rm "$TEMP_2" "$TEMP_1"

# PRINT RESULTS
echo
echo "Completed."
echo "Full output saved to $OUTPUT_FILE"
echo "Graph HTML document saved to $OUTPUT_HTML"
