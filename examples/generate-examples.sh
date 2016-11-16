#!/usr/bin/env bash

WEBERA=../../webera.sh
DEBUG=0
WORKDIR=$(pwd)

if [ -z "$@" ]; then
	printf "Usage:\t./generate-examples.sh [--every|DIR]\n\n"
	printf "Especify the directory of the example to generate,\n"
	printf "or the flag --every to generate every one of them.\n"
	exit
fi

if [ "$1" == "--every" ]; then
	EXAMPLES=$(find . -maxdepth 1 -type d | cut -d'/' -f2 | grep -v '^\.\+$' | sort | tac | tr '\n' ' ')
else
	if [ -d "$1" ]; then
		EXAMPLES="$1"
	else
		printf "ERROR: can't find directory '$1' \n"
		exit 1
	fi
fi


for E in $EXAMPLES; do
	cd $E;

	printf "generating '$E'. . . \n"

	if [ $DEBUG -gt 0 ]; then
		$WEBERA -l -L ${DEBUG} -G ../generate-examples.log
	else
		$WEBERA
	fi

	cd $WORKDIR
done

printf "\nDone.\n"
