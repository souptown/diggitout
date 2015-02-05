#!/bin/bash

TEST_WORKSPACE=test-workspace
SOURCE_REPO=test-repo
FILES_TO_EXTRACT="files-to-remove.txt" # text.txt"
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

echo ""
./git-to-dependency-repo.sh -r "$TEST_WORKSPACE/$SOURCE_REPO" -o m -d "$TEST_WORKSPACE/$EXTRACTED_FILES_FOLDER" -t "$TEST_WORKSPACE/temp-repo" -f "$FILES_TO_EXTRACT"


