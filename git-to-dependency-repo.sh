#!/bin/bash

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
SOURCE_REPO=""
PATHS_FILE=""
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
	echo "    -t  Directory in which to check out version of the real repo while processing."
	echo "    -f  File containing paths of files to remove. 1 path per line."
}

function realpath() {
	(
	cd $(dirname $1) # or  cd ${1%/*}
	echo $PWD/$(basename $1) # or  echo $PWD/${1##*/}
	)
}

STARTING_FOLDER=`pwd`

while getopts "h?vr:f:o:d:t:" opt; do
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
    t)
		TEMP_REPO=$(realpath "$OPTARG")
		;;
    f)
		PATHS_FILE=$(realpath "$OPTARG")
		;;
    esac
done

shift $((OPTIND-1))
# $@ now has file names

echo "Repository:"
echo "    "$(realpath "$SOURCE_REPO")
echo "Target folder for extracted files:"
echo "    "$TARGET_FOLDER
echo "Temp folder for repo work:"
echo "    "$TEMP_REPO
echo "Files to extract:"
for fff in $(cat "$PATHS_FILE")
do
	echo "    $fff"
done
echo ""

cd "$SOURCE_REPO"
git checkout -q master
rm -rf /repositories/diggitout/test-workspace/extracted

#gitk

CMD="$STARTING_FOLDER/extract-and-record-files.sh '$TARGET_FOLDER' '$PATHS_FILE' '$SOURCE_REPO'"
git filter-branch --tree-filter "$CMD" -d "$TEMP_REPO"

