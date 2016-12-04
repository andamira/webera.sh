#!/usr/bin/env bats

load helper

@test "    usage" {
	run webera
	assert_equal 1 "$status"

	local usage=$(printf '%s' "$output" | grep '^Usage' | cut -d' ' -f1-2)
	assert_equal "$usage" "Usage: ./webera"
	assert_line "MAIN FLAGS"
}

@test "-_  debug output" {
	run webera -_
	assert_equal "0" "$status"

	# check expeted format, and minimum number of arguments
	[[ $( echo "$output" | grep '^\[[a-z]\+\]:.\+=' | wc -l) -ge 38 ]]
}

@test "-t  _DO_PROCESS_TEMPLATES" {
	run webera -_ -t
	local value=$(weberaVarValue "$output" "args" "_DO_PROCESS_TEMPLATES" )
	assert_equal "$value" "true"
}

@test "-r  _DO_PROCESS_RESOURCES" {
	run webera -_ -r
	value=`weberaVarValue "$output" "args" "_DO_PROCESS_RESOURCES"`
	assert_equal "true" "$value"
}

@test "-w  _DO_PREVIEW_IN_BROWSER" {
	run webera -_ -w
	#output=$(weberaVarValue "$output" "args" "_DO_PREVIEW_IN_BROWSER" )
	value=$(printf '%s' "$output" | grep "^\[args\]" | grep "_DO_PREVIEW_IN_BROWSER" | cut -d':' -f3 | cut -d'=' -f2)
	assert_equal "true" "$value"
}

@test "-n  _DO_GENERATE_FILE_CONFIG" {
	run webera -_ -n
	output=$(weberaVarValue "$output" "args" "_DO_GENERATE_FILE_CONFIG" )
	assert_equal "true" "$output"
}

@test "-C  FILE_CONFIG" {
	run webera -_ -C test_weberarc
	output=$(weberaVarValue "$output" "args" "FILE_CONFIG" )
	assert_equal "test_weberarc" "$output"
}

@test "-T  DIR_TEMPLATES" {
	run webera -_ -T test_tem
	output=$(weberaVarValue "$output" "args" "DIR_TEMPLATES" )
	assert_equal "test_tem" "$output"
}

@test "-R  DIR_RESOURCES" {
	run webera -_ -R test_res
	output=$(weberaVarValue "$output" "args" "DIR_RESOURCES" )
	assert_equal "test_res" "$output"
}

@test "-O  DIR_OUTPUT" {
	run webera -_ -O test_out
	output=$(weberaVarValue "$output" "args" "DIR_OUTPUT" )
	assert_equal "test_out" "$output"
}

@test "-B  DIR_BUILD" {
	run webera -_ -B test_build
	output=$(weberaVarValue "$output" "args" "DIR_BUILD" )
	assert_equal "test_build" "$output"
}


@test "-d  OPTION_DELETE_DIR_OUTPUT" {
	run webera -_
	output=$(weberaVarValue "$output" "vdef" "OPTION_DELETE_DIR_OUTPUT" )
	assert_equal "true" "$output"

	run webera -_ -d
	output=$(weberaVarValue "$output" "args" "OPTION_DELETE_DIR_OUTPUT" )
	assert_equal "false" "$output"
}

@test "-c  OPTION_LOG_CLEAR" {
	run webera -_ 
	output=$(weberaVarValue "$output" "vdef" "OPTION_LOG_CLEAR" )
	assert_equal "false" "$output"

	run webera -_ -c
	output=$(weberaVarValue "$output" "args" "OPTION_LOG_CLEAR" )
	assert_equal "true" "$output"
}


@test "-L  OPTION_LOG_LEVEL" {
	run webera -_ -L 3
	output=$(weberaVarValue "$output" "args" "OPTION_LOG_LEVEL" )
	assert_equal 3 "$output"
}

@test "-G  FILE_LOG" {
	run webera -_ -G test_logfile
	output=$(weberaVarValue "$output" "args" "FILE_LOG" )
	assert_equal "test_logfile" "$output"
}


@test "-W  WEB_BROWSER" {
	run webera -_ -W test_browser
	output=$(weberaVarValue "$output" "args" "WEB_BROWSER" )
	assert_equal "test_browser" "$output"
}

@test "-S  SERVER_TYPE" {
	run webera -_ -S test_custom
	output=$(weberaVarValue "$output" "args" "SERVER_TYPE" )
	assert_equal "test_custom" "$output"
}

@test "-H  SERVER_HOST" {
	run webera -_ -H test_host
	output=$(weberaVarValue "$output" "args" "SERVER_HOST" )
	assert_equal "test_host" "$output"
}

@test "-P  SERVER_PORT" {
	run webera -_ -P test_port
	output=$(weberaVarValue "$output" "args" "SERVER_PORT" )
	assert_equal "test_port" "$output"
}
