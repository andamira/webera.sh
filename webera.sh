#!/usr/bin/env bash
#
## webera
#
# Author: José Luis Cruz (andamira)
# Repository: https://github.com/andamira/webera
# Description: A versatile static website generator made in Bash
# Version: 0.1.12
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
declare -A DEFINED_CMD_MAP

NESTING_LEVEL=0
NESTING_MAX=8

# reusable regexp patterns
WS="[[:space:]]" # whitespace
SED_DEL_SPACE_LEADTRAIL="s/^$WS*//;s/$WS*$//" # delete leading/trailing whitespace
SED_DEL_COMMENTS="/^$WS*#.*/d" # remove comments
SED_DEL_EMPTYLINES="/^$WS*$/d" # delete empty lines
SED_JOIN_SPLITLINES=':x; /\\$/ { N; s/\\\n//; tx }' # join lines ending in backslash


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
	printf "\t-d\t\t(don't) delete the output directory (%s)\n" "delete=$OPTION_DELETE_DIR_OUTPUT"

	echo
	printf "\t-L <NUMBER>\tlog level [0=none|1|2|3] (%s)\n" "$OPTION_LOG_LEVEL"
	printf "\t-G <FILE>\tlog file (%s)\n" "$FILE_LOG"
	printf "\t-W <BIN>\tweb browser binary (%s)\n" "$WEB_BROWSER_BIN"

	printf "\nFILE CONFIG\n"
	printf "\tYou can set all these options, and more, in $FILE_CONFIG.\n"

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
# $1 = config file to read
#
function readConfig {
	local FILE=$1

	if [ -f "$1" ]; then
		local TMPCONF="$(cat $FILE | \
			sed -e "$SED_DEL_SPACE_LEADTRAIL" | \
			sed -e "$SED_DEL_COMMENTS" -e "$SED_DEL_EMPTYLINES" | \
			sed -e "$SED_JOIN_SPLITLINES" \
		)"$'\n'
		CONFIG="$CONFIG$TMPCONF" # append to previously read configuration
	else
		if [ "$FILE" == "$FILE_CONFIG" ]; then
			printf "ERROR: Configuration file '%s' doesn't exist.\n" "$FILE_CONFIG"
			exit 3
		else
			log "file '$FILE' doesn't exist" 3 warn
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
	# TODO: search first in DIR_BUILD, if not found, don't ouput anything
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

while getopts ':trwC:T:E:B:O:dL:G:W:h:' OPTION; do
	case "$OPTION" in
		t) OPERATIONAL=true; OPTION_PROCESS_TEMPLATES=true ;;
		r) OPERATIONAL=true; OPTION_PROCESS_RESOURCES=true ;;
		w) OPERATIONAL=true; OPTION_LOAD_IN_WEB_BROWSER=true ;;

		C) FILE_CONFIG="$OPTARG" ;;

		# The following options can also be defined in $FILE_CONFIG, but
		# passing them as arguments to the script has a higher priority.

		T) ARG_OPTIONS[DIR_TEMPLATES]="$OPTARG" ;;
		E) ARG_OPTIONS[DIR_RESOURCES]="$OPTARG" ;;
		B) ARG_OPTIONS[DIR_BUILD]="$OPTARG" ;;
		O) ARG_OPTIONS[DIR_OUTPUT]="$OPTARG" ;;

		d) ARG_OPTIONS[OPTION_DELETE_DIR_OUTPUT]="$OPTARG" ;;

		L) ARG_OPTIONS[OPTION_LOG_LEVEL]="$OPTARG" ;;
		G) ARG_OPTIONS[FILE_LOG]="$OPTARG" ;;

		W) ARG_OPTIONS[WEB_BROWSER_BIN]="$OPTARG" ;;

		h|*) usage ;;
	esac
done
shift $((OPTIND-1))


# READ CONFIGURATION FROM FILES
# #############################

readConfig "/etc/weberarc"
readConfig "$HOME/.weberarc"
readConfig "$FILE_CONFIG"


# CONFIGURE SETTINGS
# ##################

# Parse the commands for processing resources
SETTINGS="$(echo "$CONFIG" | grep ^$WS*config$WS*: )"

if [ "$SETTINGS" ]; then
#	log "Configuring settings...\n====================" 1

	OLDIFS="$IFS"; IFS=$'\n'
	for S in $SETTINGS; do

		setting_name=$(echo "$S" | cut -d':' -f2 | sed -e "$SED_DEL_SPACE_LEADTRAIL")
		setting_value=$(echo "$S" | cut -d':' -f3 | sed -e "$SED_DEL_SPACE_LEADTRAIL")
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


# DEFINE COMMANDS
# ###############

DEFINED_CMD="$(echo "$CONFIG" | grep ^$WS*define_cmd$WS*: )"

if [ "$DEFINED_CMD" ]; then
	log "Defining the commands..." 1
fi

OLDIFS="$IFS"; IFS=$'\n'
for C in $DEFINED_CMD; do

	cmd_name=$(echo "$C" | cut -d':' -f2 | sed -e "$SED_DEL_SPACE_LEADTRAIL" )
	cmd_action=$(echo "$C" | cut -d':' -f3- | sed -e "$SED_DEL_SPACE_LEADTRAIL" )

	DEFINED_CMD_MAP[$cmd_name]=$cmd_action

	log "\t$cmd_name='$cmd_action'" 2
done
IFS="$OLDIFS"


# PROCESS RESOURCES
# #################

if [ $OPTION_PROCESS_RESOURCES == true ]; then

	log "Processing resources...\n====================" 1

	if [ -d "$DIR_RESOURCES" ]; then

		RESOURCE_CMD_LIST="$(echo "$CONFIG" | grep ^$WS*resource$WS*: )"

		if [ "$RESOURCE_CMD_LIST" ]; then
			RNUM=$(echo $"RESOURCE_CMD_LIST" | wc -l )
			log "Found $RNUM operations on resources..." 1
		fi

		OLDIFS="$IFS"; IFS=$'\n'
		for RCMD in $RESOURCE_CMD_LIST; do

			operation=$(echo "$RCMD" | cut -d':' -f2 | sed -e "$SED_DEL_SPACE_LEADTRAIL" )
			fileOrigin=$(echo "$RCMD" | cut -d':' -f3 | sed -e "$SED_DEL_SPACE_LEADTRAIL" )
			fileTarget=$(echo "$RCMD" | cut -d':' -f4 | sed -e "$SED_DEL_SPACE_LEADTRAIL" )

			log "\t$operation: $fileOrigin > $fileTarget" 1

			if [ ! -e "$DIR_RESOURCES/$fileOrigin" ]; then
				log "\tERROR: '$fileOrigin' don't exist" 1
				continue # XXX do break instead?
			fi

			# built-in command for resources?
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
					# NOTE: paths are adapted for resources
					if [ "${DEFINED_CMD_MAP[$operation]}" ]; then

						local CMD=$(echo ${DEFINED_CMD_MAP[$operation]} \
							| sed "s|{ORIGIN}|$DIR_RESOURCES/$fileOrigin|g" \
							| sed "s|{BUILD}|$DIR_BUILD/$fileOrigin|g" \
							| sed "s|{TARGET}|$DIR_OUTPUT/$DIR_RESOURCES/$fileTarget|g" \
						)

						# Create target paths
						if [[ "${DEFINED_CMD_MAP[$operation]}" =~ "{BUILD}" ]]; then
							mkdir -p $(dirname "$DIR_BUILD/$fileTarget")
						fi
						if [[ "${DEFINED_CMD_MAP[$operation]}" =~ "{TARGET}" ]]; then
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


# PROCESS TEMPLATES
# #################

if [ $OPTION_PROCESS_TEMPLATES == true ]; then

	log "\nProcessing templates...\n====================" 1

	if [ -d "$DIR_TEMPLATES" ]; then

		TEMPLATE_CMD_LIST="$(echo "$CONFIG" | grep ^$WS*template$WS*: )"

		if [ "$TEMPLATE_CMD_LIST" ]; then
			TNUM=$(echo $"TEMPLATE_CMD_LIST" | wc -l )
			log "Found $TNUM operations on templates..." 1
		fi


		OLDIFS="$IFS"; IFS=$'\n'
		for TCMD in $TEMPLATE_CMD_LIST; do

			operation=$(echo "$TCMD" | cut -d':' -f2 | sed -e "$SED_DEL_SPACE_LEADTRAIL" )
			fileOrigin=$(echo "$TCMD" | cut -d':' -f3 | sed -e "$SED_DEL_SPACE_LEADTRAIL" )
			fileTarget=$(echo "$TCMD" | cut -d':' -f4 | sed -e "$SED_DEL_SPACE_LEADTRAIL" )

			log "\t$operation: $fileOrigin > $fileTarget" 1

			# built-in command for templates?
			case "$operation" in
				"route")
					urlPath=$fileTarget

					log "\t$urlPath ($fileOrigin)" 1

					if [[ "$fileOrigin" && "$urlPath" ]]; then

						mkdir -p "${DIR_OUTPUT}${urlPath}"
						templateRender "$fileOrigin" > "${DIR_OUTPUT}${urlPath}/index.html"
					else
						log "\tERROR: missing arguments for 'template:route' command" 1
					fi
					;;

				*)
					# custom command?
					# NOTE: paths are adapted for templates
					if [ "${DEFINED_CMD_MAP[$operation]}" ]; then

						local CMD=$(echo ${DEFINED_CMD_MAP[$operation]} \
							| sed "s|{ORIGIN}|$DIR_TEMPLATES/$fileOrigin|g" \
							| sed "s|{BUILD}|$DIR_BUILD/$fileOrigin|g" \
							| sed "s|{TARGET}|$DIR_OUTPUT/$fileTarget|g" \
						)

						# Create target paths
						if [[ "${DEFINED_CMD_MAP[$operation]}" =~ "{BUILD}" ]]; then
							mkdir -p $(dirname "$DIR_BUILD/$fileTarget")
						fi
						if [[ "${DEFINED_CMD_MAP[$operation]}" =~ "{TARGET}" ]]; then
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

		POSTS="$(echo "$CONFIG" | grep ^$WS*post$WS: )"

		# TODO
		if [ "$POSTS" ]; then
			log "Processing posts..." 1
		fi
	else
		echo "No resources dir '$DIR_RESOURCES' found."
	fi

fi


log "Done." 1
printf "Done.\n"


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
