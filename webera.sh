#!/usr/bin/env bash
#
## webera
#
# Author: José Luis Cruz (andamira)
# Repository: https://github.com/andamira/webera
# Description: A versatile static website generator made in Bash
# Version: 0.1.7
# License: MIT
#
## Dependencies:
#
#   bash (>4), grep (with PCRE support), sed
#
## Optional Dependencies:
#
#   python | php (to use their built-in web server)
#
#
# Originally Inspired by Statix
#   https://gist.github.com/plugnburn/c2f7cc3807e8934b179e
##


# GLOBAL
# =============================================================================
#

## SETTINGS
# ----------

# PATHS
DIR_TEMPLATES=templates
DIR_RESOURCES=res
DIR_BUILD=build
DIR_OUTPUT=out

FILE_CONFIG=.weberarc

# Web Browser
WEB_BROWSER_BIN="firefox" # | chromium-browser | google-chrome | opera | elinks | ...
SERVER_PORT="8192"
SERVER_TYPE="python"

# Log
FILE_LOG=log.txt
OPTION_LOG_LEVEL=0 # 0 = no logging | 1 | 2 | 3
OPTION_CLEAR_LOG=false

# Delete output & build directories
OPTION_DELETE_DIR_OUTPUT=true
OPTION_DELETE_DIR_BUILD=true


## INTERNALS
# -----------

OPERATIONAL=false

OPTION_PROCESS_TEMPLATES=false
OPTION_PROCESS_RESOURCES=false
OPTION_LOAD_IN_WEB_BROWSER=false

# (PRE)PROCESSING
declare -A ARG_OPTIONS
declare -A RCOMMANDS_MAP

TMP_CONFIG=""

NESTING_LEVEL=0
NESTING_MAX=8


# FUNCTIONS
# =============================================================================
#

# usage
#
function usage {
	printf "Usage:\t./webera.sh -trw [ARGS]\n\n"
	printf "MAIN FLAGS\n"
	printf "\t-t\t\tdo process all templates\n"
	printf "\t-r\t\tdo process all resources\n"
	printf "\t-w\t\tpreview in web browser\n"

	printf "\nOPTIONAL\n"
	printf "\t-C <FILE>\tconfiguration file (%s)\n" $FILE_CONFIG
	echo
	printf "\t-T <DIR>\ttemplates directory (%s)\n" "$DIR_TEMPLATES"
	printf "\t-E <DIR>\tresources directory (%s)\n" "$DIR_RESOURCES"
	printf "\t-B <DIR>\tbuild directory (%s)\n" "$DIR_BUILD"
	printf "\t-O <DIR>\toutput directory (%s)\n" "$DIR_OUTPUT"
	echo
	printf "\t-L <NUMBER>\tlog level [0=none|1|2|3] (%s)\n" "$OPTION_LOG_LEVEL"
	printf "\t-G <FILE>\tlogfile (%s)\n" "$FILE_LOG"
	printf "\t-W <BIN>\tweb browser binary (%s)\n" "$WEB_BROWSER_BIN"

	printf "\nFILE CONFIG\n"
	printf "\tYou can set these and more options in $FILE_CONFIG.\n"

	exit 1
}

# log
#
# $1 = message
# $2 = minimum log level needed to show the message
function log {
	local LOG_LEVEL_MIN=1
	local LOG_LEVEL_MAX=3

	if [[ -z $2 || ( "$2" -lt "1"  ) ]]; then
		LOG_LEVEL=$LOG_LEVEL_MIN
	else
		if [[ "$LOG_LEVEL" -gt "$LOG_LEVEL_MAX" ]]; then
			LOG_LEVEL=$LOG_LEVEL_MAX
		else
			LOG_LEVEL=$2
		fi
	fi

	if [ $LOG_LEVEL -le $OPTION_LOG_LEVEL ]; then
    	echo -e "$1" >> $FILE_LOG
	fi
}

# server
#
# $1 = type of server
#
function serverSetup {

	type=$2

	case $SERVER_TYPE in
		python)
			START_SERVER="pushd $DIR_OUTPUT; python -m SimpleHTTPServer $SERVER_PORT"
			STOP_SERVER="kill \$(pgrep -f \"python -m SimpleHTTPServer\")"
			;;
		php)
			START_SERVER="php -S localhost:$SERVER_PORT -t $DIR_OUTPUT"
			STOP_SERVER="kill \$(pgrep -f \"php -S localhost\")"
			;;
		none)
			START_SERVER=""
			STOP_SERVER=""
			;;
		*)
			log "Not recognized SERVER_TYPE='$SERVER_TYPE'" 2 warn
			START_SERVER=""
			STOP_SERVER=""
			;;
	esac
}

# readConfig
#
# $1 = config file
# $2 = output variable
#
function readConfig {
	local FILE=$1

	if [ -f "$1" ]; then
		# Clean input
		#   1. remove empty lines
		#   2. remove comments
		#   3. join lines ending with backslash `\`
		printf -v "$2" "$(cat $FILE | \
			grep -ve '^$' | \
			grep -v '::space::*^#' | \
			sed ':x; /\\$/ { N; s/\\\n//; tx }' \
		)\n"
	else
		if [ "$FILE" == "$FILE_CONFIG" ]; then
			printf "ERROR: Configuration file '%s' doesn't exist.\n" "$FILE_CONFIG"
			exit 3
		else
			log "file '$1' doesn't exist" 3 warn
		fi
	fi
}

# templateParseIncludes
#
# $1 = template file name
function templateParseIncludes {

	# Check nesting
	((NESTING_LEVEL++))
	if [ $NESTING_LEVEL -gt $NESTING_MAX ]; then
		log "\tError: max nesting level ($NESTING_MAX) reached for template $1" 1
		exit
	fi

	# Parse template
	local templateFile="${DIR_TEMPLATES}/$1"
	if [ -f "$templateFile" ]; then
		local templateContent="$(<$templateFile)"
	else
		log "\tERROR: No template found '$templateFile'" 1
		return
	fi
	local directives_include=$(grep -Po '<!--\s*%include:.*?-->' "$templateFile")
	local D=''

	OLDIFS="$IFS"; IFS=$'\n'

	# Remove duplicates
	if [ "$directives_include" ]; then
		directives_include=$(echo "$directives_include" | uniq)
	fi

	for D in $directives_include; do
		local includedFileName=$(echo -n "$D" | grep -Po '(?<=%include:).*?(?=-->)')

		log "\t\t$includedFileName" 2

		# Parse included template for further includes
		local includedFileContent="$(templateParseIncludes ${includedFileName})"

		# Mass-replace directive with template contents
		templateContent="${templateContent//$D/$includedFileContent}"
	done
	IFS="$OLDIFS"

	((NESTING_LEVEL--))

	printf "%s" "$templateContent"
}

# templateRender
#
# $1 = template file name
function templateRender {

	local templateText="$(templateParseIncludes $1)"

	local directives_set=$(echo -n "$templateText" | grep -Po '<!--%set:.*?-->')
	local directives_cmd=$(echo -n "$templateText" | grep -Po '<!--%cmd:.*?-->')
	local directives_setcmd=$(echo -n "$templateText" | grep -Po '<!--%setcmd:.*?-->')
	local D=''


	# text comments
	#
	# <!--// Comment -->
	#
	templateText=$(echo "$templateText" | sed -e :a -re 's/<!--\/\/.*?-->//g;/<!--\/\//N;//ba')
	
	OLDIFS="$IFS"; IFS=$'\n'

	# set variables
	#
	# <!--%set:VARIABLE=something-->
	# <!--@VARIABLE-->
	#
	for D in $directives_set; do
		local SET=$(echo -n "$D" | grep -Po '(?<=%set:).*?(?=-->)')
		local SETVAR="${SET%%=*}"
		local SETVAL="${SET#*=}"

		log "\t\t$SETVAR = $SETVAL" 3

		# Cross-platform syntax to replace including newlines
		# http://stackoverflow.com/a/1252191
		templateText=$(echo "$templateText" \
			| sed -e ":a" -e "N" -e "\$!ba" -e "s/$D\n\?//g")
		templateText=$(echo "$templateText" \
			| sed -e ":a" -e "N" -e "\$!ba" -e "s/<!--@$SETVAR-->\n\?/$SETVAL/g")
	done

	# execute commands, render output
	#
	# <!--%cmd: ls -l -->
	#
	for D in $directives_cmd ; do
		local CMD=$(echo -n "$D" | grep -Po '(?<=%cmd:).*?(?=-->)')
		local CMDOUT=$(eval $CMD)

		log "\t\tCMD:$CMD" 3

		templateText=$(echo "$templateText" \
			| sed -e ":a" -e "N" -e "\$!ba" -e "s/$D\n\?/$CMDOUT/g")
	done

	# set variables to commands output
	#
	# <!--%setcmd:VARIABLE=ls -l-->
	# <!--@VARIABLE-->
	#
	for D in $directives_setcmd; do
		local SETCMD=$(echo -n "$D" | grep -Po '(?<=%setcmd:).*?(?=-->)')
		local SETCMDVAR="${SETCMD%%=*}"
		local SETCMDVAL="${SETCMD#*=}"
		local SETCMDOUT=$(eval $SETCMDVAL)

		log "\t\t$SETCMDVAR = $SETCMDVAL" 3

		templateText=$(echo "$templateText" \
			| sed -e ":a" -e "N" -e "\$!ba" -e "s/$D\n\?//g")
		templateText=$(echo "$templateText" \
			| sed -e ":a" -e "N" -e "\$!ba" -e "s/<!--@$SETCMDVAR-->\n\?/$SETCMDOUT/g")
	done

	IFS="$OLDIFS"

	log "" 2

	printf "$templateText"
}


# PROCESS
# =============================================================================
#

# READ ARGUMENTS
# ##############

while getopts ':trwlL:C:E:O:W:h:' OPTION; do
	case "$OPTION" in
		t) OPERATIONAL=true; OPTION_PROCESS_TEMPLATES=true ;;
		r) OPERATIONAL=true; OPTION_PROCESS_RESOURCES=true ;;
		w) OPERATIONAL=true; OPTION_LOAD_IN_WEB_BROWSER=true ;;

		C) FILE_CONFIG="$OPTARG" ;;

		# The following options can also be defined in $FILE_CONFIG, but
		# passing them as arguments to the script has a higher priority.

		L) ARG_OPTIONS[OPTION_LOG_LEVEL]="$OPTARG" ;;

		E) ARG_OPTIONS[DIR_RESOURCES]="$OPTARG" ;;
		O) ARG_OPTIONS[DIR_OUTPUT]="$OPTARG" ;;

		W) ARG_OPTIONS[WEB_BROWSER_BIN]="$OPTARG" ;;

		h|*) usage ;;
	esac
done
shift $((OPTIND-1))


# READ CONFIGURATION FROM FILE
# ############################

# Firstly load config from /etc/
readConfig "/etc/weberarc" "CONFIG"

# Secondly load config from $HOME
readConfig "$HOME/.weberarc" "TMP_CONFIG"
CONFIG="${CONFIG}${TMP_CONFIG}"

# Thirdly load config from the current project
readConfig "$FILE_CONFIG" "TMP_CONFIG"
CONFIG="${CONFIG}${TMP_CONFIG}"


# CONFIGURE SETTINGS
# ##################

# Parse the commands for processing resources
SETTINGS="$(echo "$CONFIG" | grep '^[[:space:]]*config:')"

if [ "$SETTINGS" ]; then
#	log "Configuring settings...\n====================" 1

	OLDIFS="$IFS"; IFS=$'\n'
	for S in $SETTINGS; do

		setting_name=$(echo "$S" | cut -d':' -f2 )
		setting_value=$(echo "$S" | cut -d':' -f3 )

		setting_previous_value=${!setting_name}

#		log "\tsetting: $setting_name=$setting_value (previous=$setting_previous_value)" 1

		# NOTE: There're currently no checks. Any global variable can be (re)assigned.
		printf -v $setting_name "$setting_value"
	done
fi

# Override any file settings with the script arguments
for OPT in "${!ARG_OPTIONS[@]}"; do
	printf -v ${OPT} "${ARG_OPTIONS[$OPT]}"
done


if [ $OPERATIONAL == false ]; then
	printf "In order to run the script, you must use at least one MAIN FLAG.\n\n"
	usage
	exit
fi

# START LOG
if [ $OPTION_CLEAR_LOG == true ]; then rm $FILE_LOG 2>/dev/null; fi
log "\n===============[$(date '+%Y-%m-%d %H:%M:%S')]==============${OPTION_LOG_LEVEL}" 1


# SETUP SERVER
serverSetup


# DELETE DIRECTORIES
# ##################

if [[ $OPTION_DELETE_DIR_BUILD ]]; then
	rm -r "$DIR_BUILD" 2>/dev/null
fi

if [[ $OPTION_DELETE_DIR_OUTPUT && ( \
		$OPTION_PROCESS_RESOURCES == true || \
		$OPTION_PROCESS_TEMPLATES == true \
	) ]]; then

	rm -r "$DIR_OUTPUT" 2>/dev/null
fi


# PROCESS RESOURCES
# #################

if [ $OPTION_PROCESS_RESOURCES == true ]; then

	log "Processing resources...\n====================" 1

	if [ -d "$DIR_RESOURCES" ]; then

		# Parse the commands for processing resources
		RCOMMANDS="$(echo "$CONFIG" | grep '^[[:space:]]*rcommand:')"

		if [ "$RCOMMANDS" ]; then
			log "Parsing rcommands..." 1
		fi

		OLDIFS="$IFS"; IFS=$'\n'
		for C in $RCOMMANDS; do

			rcmdname=$(echo "$C" | cut -d':' -f2 )
			rcommand=$(echo "$C" | cut -d':' -f3- )

			RCOMMANDS_MAP[$rcmdname]=$rcommand

			log "\t$rcmdname='$rcommand'" 2
		done
		IFS="$OLDIFS"


		RESOURCES="$(echo "$CONFIG" | grep '^[[:space:]]*resource:')"

		if [ "$RESOURCES" ]; then
			log "Processing resources..." 1
		fi

		OLDIFS="$IFS"; IFS=$'\n'
		for R in $RESOURCES; do
			
			# TODO: allow optional field for custom configuration
			# cleaner way would be to define custom tags before using them

			operation=$(echo "$R" | cut -d':' -f2 )
			fileOrigin=$(echo "$R" | cut -d':' -f3 )
			fileTarget=$(echo "$R" | cut -d':' -f4 )

			log "\t$operation: $fileOrigin > $fileTarget" 1

			if [ ! -e "$DIR_RESOURCES/$fileOrigin" ]; then
				log "\tERROR: '$fileOrigin' don't exist" 1
				continue # XXX do break instead?
			fi

			# built-in command? 
			case "$operation" in
				"copy")
					# NOTE: without resources dir prefix
					#mkdir -p $DIR_OUTPUT/$(dirname $fileTarget)
					#cp -r $DIR_RESOURCES/$fileOrigin $DIR_OUTPUT/$fileTarget

					# NOTE: with resources dir prefix
					mkdir -p $DIR_OUTPUT/$DIR_RESOURCES/$(dirname $fileTarget)
					cp -r "$DIR_RESOURCES/$fileOrigin" \
						"$DIR_OUTPUT/$DIR_RESOURCES/$fileTarget"
					;;
				*)
					# custom command?
					if [ "${RCOMMANDS_MAP[$operation]}" ]; then

						# TODO: move up to add support for these tags in built-in commands
						CMD=$(echo ${RCOMMANDS_MAP[$operation]} \
							| sed "s|{ORIGIN}|$DIR_RESOURCES/$fileOrigin|g" \
							| sed "s|{BUILD}|$DIR_BUILD/$fileOrigin|g" \
							| sed "s|{TARGET}|$DIR_OUTPUT/$DIR_RESOURCES/$fileTarget|g" \
						)

						# Create target paths
						if [[ "${RCOMMANDS_MAP[$operation]}" =~ "{BUILD}" ]]; then
							mkdir -p $(dirname "$DIR_BUILD/$fileTarget")
						fi
						if [[ "${RCOMMANDS_MAP[$operation]}" =~ "{TARGET}" ]]; then
							mkdir -p $(dirname "$DIR_OUTPUT/$DIR_RESOURCES/$fileTarget")
						fi

						log "\tExecuting: $CMD" 3
						eval $CMD # HACK dangerous

					else
						log "ERROR: operation '$operation' not recognized" 1
					fi
					;;
			esac

		done
		IFS="$OLDIFS"
		
	else
		echo "No resources dir '$DIR_RESOURCES' found."
	fi
fi


# PROCESS PAGES
# #############

if [ $OPTION_PROCESS_TEMPLATES == true ]; then

	log "\nProcessing templates...\n====================" 1

	PAGES="$(echo "$CONFIG" | grep '^[[:space:]]*page:')"

	if [ "$PAGES" ]; then
		log "Processing pages..." 1
	fi

	OLDIFS="$IFS"; IFS=$'\n'
	for P in $PAGES; do

		templateName=$(echo "$P" | cut -d':' -f2 )
		templatePath=$(echo "$P" | cut -d':' -f3 )

		log "\t$templatePath ($templateName)" 1

		if [[ "$templateName" && "$templatePath" ]]; then
			mkdir -p "${DIR_OUTPUT}${templatePath}"
			templateRender "$templateName" > "${DIR_OUTPUT}${templatePath}/index.html"
		fi
	done
	IFS="$OLDIFS"

	POSTS="$(echo "$CONFIG" | grep '^[[:space:]]*post:')"

	# TODO
	if [ "$POSTS" ]; then
		log "Processing posts..." 1
	fi
fi

printf "Done.\n"
log "Done." 1


# LOAD WEBSITE (RUN SERVER & BROWSER)
# ############

if [ $OPTION_LOAD_IN_WEB_BROWSER == true ]; then

	printf "Loading website in '$WEB_BROWSER_BIN'..."

	if [ ! -z "$START_SERVER" ]; then
		printf " (Use CTRL+C to stop the web server)\n"
	else
		echo
	fi

	RUN_BROWSER="$WEB_BROWSER_BIN http://localhost:$SERVER_PORT &"

	case $OPTION_LOG_LEVEL in
		0)
			# no CLI output whatsoever
			REDIR_CLI_OUTPUT="> /dev/null 2>&1"
			;;
		1)
			# hide errors
			REDIR_CLI_OUTPUT="2>/dev/null"
			;;
		*)
			# output everything
			REDIR_CLI_OUTPUT=""
			;;
	esac

	sleep 1s && eval $RUN_BROWSER > /dev/null 2>&1

	if [ ! -z "$START_SERVER" ]; then
		eval "$STOP_SERVER $REDIR_CLI_OUTPUT"; eval "$START_SERVER $REDIR_CLI_OUTPUT"
	fi
fi
