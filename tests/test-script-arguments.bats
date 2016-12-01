#!/usr/bin/env bats

load header

@test "no arguments; shows usage" {
	run webera
	[ "$status" -eq 1 ]

	local usage=$(echo "$output" | grep '^Usage' | cut -d' ' -f1-2)
	[ "$usage" == "Usage: ./webera" ]
}

