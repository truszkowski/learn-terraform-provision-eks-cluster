#!/bin/bash

if [ $# -ne 1 ]
then
	echo "usage $0: <number-of-bulk-nginx-services>"
	exit 1
elif [ $1 -gt 100 ]
then
	echo "too many services"
	exit 2
elif [ $1 -lt 2 ]
then
	echo "expected more than 1 service"
	exit 3
fi

ls bulk-nginx* | grep -v bulk-nginx1.yaml | xargs rm -vf

for n in `seq 2 $1`
do 
	cat bulk-nginx1.yaml | \
		sed -e 's/nginx-1/nginx-'$n'/g' | \
		sed -e 's/8001/'$((8000+$n))'/g' \
		> bulk-nginx${n}.yaml
done
