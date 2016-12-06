#!/usr/bin/env bash

. ./helper.bash

test_arguments() {
	declare default newval

	test_h1 "Script Arguments"

	test_h2 "Usage"

	assert_raises "webera" "1"
	assert "webera -h | grep '^Usage' | cut -d' ' -f1-2" \
		"Usage: ./webera"


	# FIXME DEBUG
	echo " test1: $(webera -h | grep '^Usage')"
	echo " test2: $(../webera -h | grep '^Usage')"


	test_h2 "Debug"

	assert_raises "webera -_" "0"

	local -r defaults="$(webera -_)"

	# Check expected format, and the minimum number of arguments
	newval=$( echo "$defaults" | grep '^\[[a-z]\+\]:.\+=' | wc -l)
	[[ "$newval" -ge 38 ]]
	assert_raises "echo $?" "0"


	test_h2 "Main Flags"

	newval=$(weberaVarValue "$(webera -_t)" \
		'args' '_DO_PROCESS_TEMPLATES')
	assert "echo $newval" "true"

	newval=$(weberaVarValue "$(webera -_r)" \
		'args' '_DO_PROCESS_RESOURCES')
	assert "echo $newval" "true"

	newval=$(weberaVarValue "$(webera -_w)" \
		'args' '_DO_PREVIEW_IN_BROWSER')
	assert "echo $newval" "true"

	newval=$(weberaVarValue "$(webera -_n)" \
		'args' '_DO_GENERATE_FILE_CONFIG')
	assert "echo $newval" "true"

	
	test_h2 "File Paths"

	default=$(weberaVarValue "$defaults" 'vdef' 'FILE_CONFIG')
	assert "echo $default" ".weberarc"
	newval=$(weberaVarValue "$(webera -_C test_weberarc)" \
		'args' 'FILE_CONFIG')
	assert "echo $newval" "test_weberarc"


	test_h2 "Dir Paths"

	default=$(weberaVarValue "$defaults" 'vdef' 'DIR_TEMPLATES')
	assert "echo $default" "tem"
	newval=$(weberaVarValue "$(webera -_T test_tem)" \
		'args' 'DIR_TEMPLATES')
	assert "echo $newval" "test_tem"

	default=$(weberaVarValue "$defaults" 'vdef' 'DIR_RESOURCES')
	assert "echo $default" "res"
	newval=$(weberaVarValue "$(webera -_R test_res)" \
		'args' 'DIR_RESOURCES')
	assert "echo $newval" "test_res"

	default=$(weberaVarValue "$defaults" 'vdef' 'DIR_OUTPUT')
	assert "echo $default" "out"
	newval=$(weberaVarValue "$(webera -_O test_out)" \
		'args' 'DIR_OUTPUT')
	assert "echo $newval" "test_out"

	default=$(weberaVarValue "$defaults" 'vdef' 'DIR_BUILD')
	assert "echo $default" "build"
	newval=$(weberaVarValue "$(webera -_B test_build)" \
		'args' 'DIR_BUILD')
	assert "echo $newval" "test_build"


	test_h2 "Switch Flags"

	default=$(weberaVarValue "$defaults" \
		'vdef' 'OPTION_DELETE_DIR_OUTPUT')
	assert "echo $default" "true"
	newval=$(weberaVarValue "$(webera -_d)" \
		'args' 'OPTION_DELETE_DIR_OUTPUT')
	assert "echo $newval" "false"

	default=$(weberaVarValue "$defaults" \
		'vdef' 'OPTION_LOG_CLEAR')
	assert "echo $default" "false"
	newval=$(weberaVarValue "$(webera -_c)" \
		'args' 'OPTION_LOG_CLEAR')
	assert "echo $newval" "true"


	test_h2 "Log"

	default=$(weberaVarValue "$defaults" 'vdef' 'OPTION_LOG_LEVEL')
	assert "echo $default" "0"
	newval=$(weberaVarValue "$(webera -_L3)" \
		'args' 'OPTION_LOG_LEVEL')
	assert "echo $newval" "3"

	default=$(weberaVarValue "$defaults" 'vdef' 'FILE_LOG')
	assert "echo $default" "log.txt"
	newval=$(weberaVarValue "$(webera -_G test_logfile)" \
		'args' 'FILE_LOG')
	assert "echo $newval" "test_logfile"


	test_h2 "Website Preview"

	default=$(weberaVarValue "$defaults" 'vdef' 'WEB_BROWSER')
	assert "echo $default" "firefox"
	newval=$(weberaVarValue "$(webera -_W test_browser)" \
		'args' 'WEB_BROWSER')
	assert "echo $newval" "test_browser"

	default=$(weberaVarValue "$defaults" 'vdef' 'SERVER_TYPE')
	assert "echo $default" "python"
	newval=$(weberaVarValue "$(webera -_S test_custom)" \
		'args' 'SERVER_TYPE')
	assert "echo $newval" "test_custom"

	default=$(weberaVarValue "$defaults" 'vdef' 'SERVER_HOST')
	assert "echo $default" "localhost"
	newval=$(weberaVarValue "$(webera -_H test_host)" \
		'args' 'SERVER_HOST')
	assert "echo $newval" "test_host"

	default=$(weberaVarValue "$defaults" 'vdef' 'SERVER_PORT')
	assert "echo $default" "8192"
	newval=$(weberaVarValue "$(webera -_P 9000)" \
		'args' 'SERVER_PORT')
	assert "echo $newval" "9000"

	test_endline
}

test_arguments
assert_end arguments
