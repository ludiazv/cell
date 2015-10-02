#!/bin/bash
# ATLO IDEAS CELLCONF
# This is basic script to retrieve configuration and install configuration files or data files from specific repository to complement confd tool by kelseyhightower https://github.com/kelseyhightower/confd
#
# This simple utility needs:
# CONFCELL_URL: url for retrieving manifest file. for example http://bucket.s3.aws.com/file.confcell
# CONFCELL_MANIFEST_ID: Manifiest ID
#
#  Usage: confcell.sh [<url>] [<manfest_id>]
#    <url> 				optional 
#    <manifest_id>      
#
VERSION="0 alfa"
URL=${CONFCELL_URL}
MAN_ID=${CONFCELL_MANIFEST_ID}

# minimal parmeter parsing
if [ "$1" != "" ]; then
	URL=$1
fi
if [ "$2" != "" ]; then
    MAN_ID=$2
fi
if [ "$MAN_ID" == ""  -o "$URL" == ""  ]; then
	echo "Error:No avaible parameters for please provide parameters or user ENV vars CONFCELL_URL & CONFCELL_MANIFEST_ID"
	exit 1
fi

# --- Some functions to be used in main code----
clean_up ()
{
	rm -f $TMP_FILE.tmp
	rm -f $TMP_FILE
}

check_manifest ()
{
	rid=`echo "$1" | sed 's/^[ \t]*//g' | sed 's/[ \s]*$//g'`  # trim argument
	if [[ "$rid" != "$MAN_ID" ]]; then
		clean_up
		echo "Error: Manifest file not valid Instance MAN_ID=$MAN_ID vs File MAN_ID=$1"
		exit 1
	fi
}

get_file ()
{
	wget --quiet -O $2 URL
}

#function get_tar_gz
# {

	#}
#function get_tar_bzip2
# {

	#}


# ----- Excution  -----

START_TIME=$(date +%s)
OS_TYPE=$(uname)
if [ "$OS_TYPE" = "Darwin" ]; then
	# MAC OS + BSD
	BASE_URL=`echo "$URL" | sed -E 's/(.+\/).+$/\1/'`
else
	# GNU
	BASE_URL=`echo "$URL" | sed -r 's/(.+\/).+$/\1/'`
fi


echo "Atlo Ideas Confcell [$VERSION] at " $(date -uIseconds)
echo "URL: $URL"
echo "BASE_URL: $BASE_URL"
echo "MAN_ID: $MAN_ID"

# step 1. Look up for the manifest file
TMP_FILE=confcell_tmp.$MAN_ID
wget --quiet -O $TMP_FILE.tmp -t 5 $URL
if [ "$?" != "0" ]; then 
	echo "The $URL can't be downloaded"
	rm -f $TMP_FILE.tmp
	exit 1
fi
echo "Step 1 OK -> Donloaded manifest $TMP_FILE"

# Step 2. Parse manifest file
# Remove comments
awk 'NF{gsub(/^[ \t]*#.*/,"");print}' $TMP_FILE.tmp | grep -v '^$' > $TMP_FILE # Clean coments
# iterate thru file to execute
CMD_COUNTER=0
FILE_COUNTER=0
cat $TMP_FILE | while read line
do

	if [[ "$line" =~  (Manifest_ID=)(.*)$ ]]; then
		check_manifest ${BASH_REMATCH[2]}
		echo "Manifest checked: $MAN_ID"
	fi
	if [[ "$line" =~  (cp=)(.*)$ ]]; then
		echo ${BASH_REMATCH[0]} / ${BASH_REMATCH[1]} / ${BASH_REMATCH[2]}
		FILE_COUNTER=FILE_COUNTER + 1
	fi
	if [[ "$line" =~  (cpz=)(.*)$ ]]; then
		echo ${BASH_REMATCH[0]} / ${BASH_REMATCH[1]} / ${BASH_REMATCH[2]}
	fi
	if [[ "$line" =~  (cpb=)(.*)$ ]]; then
		echo ${BASH_REMATCH[0]} / ${BASH_REMATCH[1]} / ${BASH_REMATCH[2]}
	fi
	if [[ "$line" =~  (cmd=)(.*)$ ]]; then
		CMDS[CMD_COUNTER]=${BASH_REMATCH[2]}
	fi
	
done
echo "Step 2 OK -> $FILE_COUNTER Files downloaded and processed."

# Step 3 execute commands in order of appearence
for i in "${CMDS[@]}"
do
	
done

# Last step remove temporal manifests
END_TIME=$(date +%s)
clean_up
echo "Done! [$(($END_TIME - $START_TIME))] seconds."
