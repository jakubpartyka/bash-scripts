#!/bin/bash

# iterates over pods matching a regex ($1) and looks for ERROR messages in logs

TMP=$IFS
IFS=$'\n'

if [[ $# -ne 1 ]] ; then
	echo "provide one arg for grep"
	exit 1
fi

for pod in $(kubectl get pods --all-namespaces | grep $1) ; do
	line=$(echo $pod | tr -s " ")
	NS=$(echo $line | cut -d' ' -f1)
	POD=$(echo $line | cut -d' ' -f2)
	echo "POD: $POD, NAMESPACE: $NS"
	kubectl logs -n "$NS" "$POD" | grep ERROR
	echo -e "\n"
done

IFS=$TMP
