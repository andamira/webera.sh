#!/usr/bin/env bash

# import testing library
. extern/assert.sh -v

# import webera functions
. <( sed "\$d" ../webera ) &>>/dev/null

# webera binary wrapper
webera() { ../webera "$@" 2>/dev/null; }


# Generic Helper Functions
# ========================

test_endline() {
	if [[ "$DEBUG" -gt 0 ]]; then
		printf '\n----------------' "$@"
	fi
}
test_h1() {
	if [[ "$DEBUG" -gt 0 ]]; then
		printf '\nTesting %s:\n--------------------------------\n' "$@"
	fi
}
test_h2() {
	if [[ "$DEBUG" -gt 0 ]]; then
		printf '\ntesting %s ' "$@"
	fi
}
test_h3() {
	if [[ "$DEBUG" -gt 0 ]]; then
		printf '\n  testing %s ' "$@"
	fi
}

test_setup() {
	WEBERA_TEST_DIR=$(mktemp -d)
}
test_teardown() {
	[[ -d "$WEBERA_TEST_DIR" ]] && rm -rf "$WEBERA_TEST_DIR"
}


# Webera Specific Helper Functions
# ================================

# Parse a list of variables in debug info format
# and return the corresponding value.
#
#  [$varType]::$varName=$varValue
#
weberaVarValue() {
	local webera_vars="$1"
	local varType="$2"
	local varName="$3"

	shopt -s extglob
	local varTypesAllowed='@(vdef|file|args)'

	case "$varType" in
		$varTypesAllowed) ;;
		*) printf '%s' "ERROR: Unknown var type '$varType'." 1>&2 ;;
	esac
	shopt -u extglob

	printf '%s' "$webera_vars" \
		| grep "^\[$varType\]:.*:$varName=" \
		| cut -d':' -f3 \
		| cut -d'=' -f2
}

