#!/usr/bin/env bash

if [ -z "${SETUP_DONE}" ]; then
	export SETUP_DONE=true

	# Force to use local webera version
	export PATH="$BATS_TEST_DIRNAME/..:$PATH"
fi
