#!/bin/bash

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
SOURCE_REPO=""
SOURCE_FILES=""
DEPENDENCY_REPO_TYPE=""
TARGET_FOLDER=""
VERBOSE=0

function show_help() {
	SCRIPT_NAME=`basename $0`
	echo "This script removes the specified file from the history of a git repo, replacing it with a dependency repository reference."
	echo ""
	echo "Supported dependency repositories are Maven and NuGet."
	echo ""
	echo "Use:"
	echo "    $SCRIPT_NAME <options> file1 file2 ..."
	echo ""
	echo "Options:"
	echo "    -h"
	echo "    -?  Show this help message"
	echo "    -r  Path to a local git repository"
	echo "    -o  Type of output or dependency repository. Valid values are 'm' for Maven and 'n' for NuGet"
	echo "    -d  Directory in which to place the versioned files"
}

function realpathfoo { echo $(cd $(dirname $1); pwd)/$(basename $1); }

function realpath() {
	(
	cd $(dirname $1) # or  cd ${1%/*}
	echo $PWD/$(basename $1) # or  echo $PWD/${1##*/}
	)
}

STARTING_FOLDER=`pwd`

while getopts "h?vr:f:o:d:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    v)  
		VERBOSE=1
        ;;
    r)  
		SOURCE_REPO=$(realpath "$OPTARG")
        ;;
    o)  
		DEPENDENCY_REPO_TYPE=$OPTARG
        ;;
    d)
		TARGET_FOLDER=$(realpath "$OPTARG")
		;;
    esac
done

shift $((OPTIND-1))
# $@ now has file names
SOURCE_FILES=( "$@" )

echo "Repository:"
echo "    "$(realpath "$SOURCE_REPO")
echo "Target folder for extracted files:"
echo "    "$TARGET_FOLDER
echo "Files to extract:"
for FILE in "${SOURCE_FILES[@]}"
do
   echo "    $FILE"
done

cd "$SOURCE_REPO"
git checkout -q master
rm -rf /repositories/diggitout/test-workspace/extracted

#RMFILES=$(realpath "../rmfiles.sh")
#CMD="/repositories/diggitout/extract-and-record-files.sh \"/repositories/diggitout/test-workspace/extracted\" \"/repositories/diggitout/test-workspace/test-repo/binary.bin\" \"/repositories/diggitout/test-workspace/test-repo/binary2.bin\""
CMD="/repositories/diggitout/extract-and-record-files.sh \"/repositories/diggitout/test-workspace/extracted\" \"binary.bin\" \"binary2.bin\""
#git filter-branch --index-filter "$CMD" -- --all
git filter-branch -f --tree-filter "$CMD" -- --all

