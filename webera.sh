#!/bin/bash
#
# webera
#
# Description: A shellscript for static website generation
#
# Version: 0.1.2
# Author: José Luis Cruz
# Repository: https://github.com/andamira/webera
# License: MIT
# Originally Inspired by: https://gist.github.com/plugnburn/c2f7cc3807e8934b179e
#
# Dependencies: bash 4, grep -P, sed
# Optional Dependencies:
#   - python | php (for their built-in web server)
#   - firefox | chromium-browser | google-chrome | opera | ... (any browser)
#


# GLOBALS
# =======
#

## PATHS
# (Paths are by default relative to the current working folder)

DIR_TEMPLATES=templates
DIR_RESOURCES=res
DIR_BUILD=build
DIR_OUTPUT=html

FILE_CONFIG=.weberarc
FILE_LOG=log.txt

## TESTING

OPTION_LOG_LEVEL=0 # 0 = no logging | 1 | 2 | 3

WEB_BROWSER_BIN="firefox" # | chromium-browser | google-chrome | opera | elinks | ...
SERVER_PORT="8192"

# Server with Python
#
START_SERVER="pushd $DIR_OUTPUT; python -m SimpleHTTPServer $SERVER_PORT"
STOP_SERVER="kill \$(pgrep -f \"python -m SimpleHTTPServer\")"
#
# Server with PHP
#
#START_SERVER="php -S localhost:$SERVER_PORT -t $DIR_OUTPUT"
#STOP_SERVER="kill \$(pgrep -f \"php -S localhost\")"

NESTING_LEVEL=0
NESTING_MAX=8

## OPTIONS

OPERATIONAL=false
OPTION_PROCESS_TEMPLATES=false
OPTION_PROCESS_RESOURCES=false
OPTION_LOAD_IN_WEB_BROWSER=false
OPTION_CLEAR_LOG=false
#OPTION_DELETE_OUTPUT=false # TODO

## (PRE)PROCESSING

declare -A RCOMMANDSMAP



# FUNCTIONS
# =========
#

function usage {
	printf "Usage:\t./webera.sh -trb [ARGS]\n\n"
	printf "MAIN FLAGS\n"
	printf "\t-t\t\tdo process all templates\n"
	printf "\t-r\t\tdo process all resources\n"
	printf "\t-w\t\topen website in browser\n"
	printf "\nOPTIONAL\n"
	printf "\t-C <FILE>\tconfiguration file (%s)\n" $FILE_CONFIG
	printf "\t-T <DIR>\ttemplates directory (%s)\n" "$DIR_TEMPLATES"
	printf "\t-E <DIR>\tresources directory (%s)\n" "$DIR_RESOURCES"
	printf "\t-O <DIR>\toutput directory (%s)\n" "$DIR_OUTPUT"
	echo
	#printf "\t-d <DIR>\tdelete output directory (%s)\n" "$OPTION_DELETE_OUTPUT/" # TODO

	printf "\t-W <BIN>\tweb browser binary (%s)\n" "$WEB_BROWSER_BIN"
	printf "\t-L <NUMBER>\tlog level [0=don't|1|2|3] (%s)\n" "$OPTION_LOG_LEVEL"
	printf "\t-G <FILE>\tlogfile (%s)\n" "$FILE_LOG"
	printf "\t-l\t\tclear log (%s)\n" "$OPTION_CLEAR_LOG"
	exit 1
}

# log
#
# $1 = message
# $2 = minimum log level needed to show the message
function log {
	if [[ -z $2 || ( "$2" -lt "1"  ) ]]; then
		LOG_LEVEL=1 # default minimum threshold
	else
		LOG_LEVEL=$2
	fi

	if [ $LOG_LEVEL -le $OPTION_LOG_LEVEL ]; then
    	echo -e "$1" >> $FILE_LOG
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


# GET OPTIONS
# ###########

while getopts ':trwlL:C:E:O:W:h:' OPTION; do
	case "$OPTION" in
		t) OPERATIONAL=true; OPTION_PROCESS_TEMPLATES=true ;;
		r) OPERATIONAL=true; OPTION_PROCESS_RESOURCES=true ;;
		w) OPERATIONAL=true; OPTION_LOAD_IN_WEB_BROWSER=true ;;

		l) OPTION_CLEAR_LOG=true ;;
		L) OPTION_LOG_LEVEL="$OPTARG" ;;

		C) FILE_CONFIG="$OPTARG" ;;
		E) DIR_RESOURCES="$OPTARG" ;;
		O) DIR_OUTPUT="$OPTARG" ;;

		W) WEB_BROWSER_BIN="$OPTARG" ;;

		h|*) usage ;;
	esac
done
shift $((OPTIND-1))


if [ $OPERATIONAL == false ]; then
	printf "You must use at least one main flag\n\n"
	usage
	exit
fi

if [ -f "$FILE_CONFIG" ]; then
	CONFIG="$(cat $FILE_CONFIG | grep -ve '^$' | grep -v '^#')"
else
	printf "ERROR: Routes config file '%s' doesn't exist.\n" "$FILE_CONFIG"
	exit 3
fi


# START LOG

if [ $OPTION_CLEAR_LOG == true ]; then rm $FILE_LOG 2>/dev/null; fi
log "\n$(date '+%Y-%m-%d %H:%M:%S')\n------------" 1


# PROCESS RESOURCES
# #################

if [ $OPTION_PROCESS_RESOURCES == true ]; then

	log "Processing resources...\n====================" 1

	if [ -d "$DIR_RESOURCES" ]; then

		# Parse the commands for processing resources
		RCOMMANDS="$(echo "$CONFIG" | grep '^rcommand:')"

		if [ "$RCOMMANDS" ]; then
			log "Parsing rcommands..." 1
		fi

		OLDIFS="$IFS"; IFS=$'\n'
		for C in $RCOMMANDS; do

			rcmdname=$(echo "$C" | cut -d':' -f2 )
			rcommand=$(echo "$C" | cut -d':' -f3- )

			RCOMMANDSMAP[$rcmdname]=$rcommand

			log "\t$rcmdname='$rcommand'" 2
		done
		IFS="$OLDIFS"


		RESOURCES="$(echo "$CONFIG" | grep '^resource:')"

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
					if [ "${RCOMMANDSMAP[$operation]}" ]; then

						# TODO: move up to add support for these tags in built-in commands
						CMD=$(echo ${RCOMMANDSMAP[$operation]} \
							| sed "s|{ORIGIN}|$DIR_RESOURCES/$fileOrigin|g" \
							| sed "s|{BUILD}|$DIR_BUILD/$fileOrigin|g" \
							| sed "s|{TARGET}|$DIR_OUTPUT/$DIR_RESOURCES/$fileTarget|g" \
						)

						# Create target paths
						if [[ "${RCOMMANDSMAP[$operation]}" =~ "{BUILD}" ]]; then
							mkdir -p $(dirname "$DIR_BUILD/$fileTarget")
						fi
						if [[ "${RCOMMANDSMAP[$operation]}" =~ "{TARGET}" ]]; then
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

	PAGES="$(echo "$CONFIG" | grep '^page:')"

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

	POSTS="$(echo "$CONFIG" | grep '^post:')"

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
	echo -e "Loading website in '$WEB_BROWSER_BIN'... (Use CTRL+C to stop the web server)"

	RUN_BROWSER="$WEB_BROWSER_BIN http://localhost:$SERVER_PORT &"

	case $OPTION_LOG_LEVEL in
		0)
			# no CLI output whatsoever
			REDIR_CLI_OUTPUT="> /dev/null 2>&1"
			;;
		1)
			# hide errors
			REDIR_CLI_OUTPUT="2> /dev/null"
			;;
		*)
			# output everything
			REDIR_CLI_OUTPUT=""
			;;
	esac

	sleep 1s && eval $RUN_BROWSER > /dev/null 2>&1
	eval "$STOP_SERVER $REDIR_CLI_OUTPUT"; eval "$START_SERVER $REDIR_CLI_OUTPUT"
fi

