#!/bin/bash

TEST_WORKSPACE=test-workspace
SOURCE_REPO=test-repo
FILE_TO_EXTRACT="binary.bin binary2.bin" # text.txt"
EXTRACTED_FILES_FOLDER=extracted

# remove and re-create the test working dir
if [ -d $TEST_WORKSPACE ]; then
	printf "Removing existing files... "
	rm -rf "$TEST_WORKSPACE"/*
	echo "Done."
else
	printf "Creating workspace... "
	mkdir -v "$TEST_WORKSPACE"
	echo "Done."
fi

mkdir "$TEST_WORKSPACE/$EXTRACTED_FILES_FOLDER"

# extract the test repo into the working dir
unzip -q test-repo -d $TEST_WORKSPACE

cd $TEST_WORKSPACE
echo ""
eval "../git-to-dependency-repo.sh -r \"$SOURCE_REPO\" -o m -d \"$EXTRACTED_FILES_FOLDER\" $FILE_TO_EXTRACT"


