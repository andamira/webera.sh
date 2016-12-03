#!/usr/bin/env bash

if [ -z "${WEBERA_TEST_DIR}" ]; then
	WEBERA_TEST_DIR=$(mktemp -d)

	# add webera to path
	export PATH="$BATS_TEST_DIRNAME/..:$PATH"

	# import webera functions
	# that is everything except the last line
	source <( sed "\$d" $BATS_TEST_DIRNAME/../webera )

fi
