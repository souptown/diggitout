#!/bin/bash

set -e

# Each parameter after the first is the path to a folder or file that needs
# to be moved into a folder specified by the first parameter. Files in any
# folder that is passed in will be recursed over. When extracted, files will
# be compared with existing files of a similar base name and only
# copied if an md5 hash of the files differs from all existing of that
# base name. When copied, the file name, its version number, and its md5
# hash will be written to a properties file.

targetFolder=$1
pathsFile=$2
repoFolder=$3
manifest="$targetFolder/manifest.sh"
restoreFile="restore-extracted-files.sh"

echo ""

startingFolder=`pwd`
if [ 1 -eq 1 ]; then
	echo "Starting folder = $startingFolder"
	echo "targetFolder=$targetFolder"
	echo "pathsFile=$pathsFile"
	echo "manifest=$manifest"
	echo "restoreFile=$restoreFile"
	echo ""
	echo "git ls-files:"
	git ls-files
	echo ""
fi

# make sure the target folder exists
if [ ! -d $targetFolder ]; then
	mkdir -p "$targetFolder"
	echo "Created folder to hold extracted files."
fi

# make sure the manifest file exists
if [ ! -f "$manifest" ]; then	
	touch "$manifest"
	echo "#!/bin/bash" >> "$manifest"
	echo "Created manifest file for extracted files."
fi

# Create bash file for restoring extracted files
echo "Restore file: $restoreFile"
printf "Verifying new restore file exists... "
rm -f $restoreFile
echo "#!/bin/bash" >> $restoreFile
echo "Done."

set +e

function getFileHash {
	ls -a | 2>&1 >/dev/null
	md5sum -b "$1" | cut -d ' ' -f1
}

function makeBashVariableName {
	local temp="var$1"
	temp=${temp// /_}
	temp=${temp//-/_}
	temp=${temp//\./_}
	echo $temp
}

function extractFile() {
	local FILE="$1"
	local BASENAME=$(basename "$FILE")
	local EXTENSION="${BASENAME##*.}"
	local FILENAME_SANS_EXTENSION="${BASENAME%.*}"
	local CHECKSUM=$(getFileHash $startingFolder/$FILE)

	if [ 1 -eq 1 ]; then
		echo "    file         : $FILE"
		echo "    basename     : $BASENAME"
		echo "    no extension : $FILENAME_SANS_EXTENSION"
		echo "    extension    : $EXTENSION"
		echo "    checksum     : $CHECKSUM"
	fi

	# source the manifest file so we can look up checksums for existing files
	. "$manifest"
	echo "    Checking for existing extracted files named $FILENAME_SANS_EXTENSION*.$EXTENSION"
	local OTHER_VERSIONS_COUNT=$(ls -Q $targetFolder/$FILENAME_SANS_EXTENSION*.$EXTENSION 2>/dev/null | wc -l | cut -d ' ' -f7)
	local found=no
	for ((i=1; i<=OTHER_VERSIONS_COUNT; i++))
	do
		if [ "$FILENAME_SANS_EXTENSION" == "" ]; then
			local temp="$i.$EXTENSION"
		else
			local temp="$FILENAME_SANS_EXTENSION-$i.$EXTENSION"
		fi
		temp=$(makeBashVariableName "$temp")
		local found_hash=${!temp}
		if [ "$found_hash" == "$CHECKSUM" ]; then
			found=$i
			echo "    Found $temp"
		fi
	done
	if [ "$found" == "no" ]; then
		echo "      Not found"
		if [ "$FILENAME_SANS_EXTENSION" == "" ]; then
			local VERSIONED_FILE_NAME="$OTHER_VERSIONS_COUNT.$EXTENSION"
		else
			local VERSIONED_FILE_NAME="$FILENAME_SANS_EXTENSION-$OTHER_VERSIONS_COUNT.$EXTENSION"
		fi
		local propertyName=$(makeBashVariableName "$VERSIONED_FILE_NAME")
		echo "      Copying $FILE to $targetFolder/$VERSIONED_FILE_NAME"
		cp $startingFolder/$FILE $targetFolder/$VERSIONED_FILE_NAME
		echo "${propertyName}=$CHECKSUM" >> $manifest
		echo "cp $targetFolder/$VERSIONED_FILE_NAME $FILE" >> $restoreFile
	else
		echo "      Found with version=$found"
		echo "cp $targetFolder/$FILENAME_SANS_EXTENSION-$found.$EXTENSION $FILE" >> $restoreFile
	fi
	echo "      Deleting $FILE"
	rm -f "$FILE" > /dev/null 2>&1
}

echo "Reading list of files to extract..."
cd ../..
for line in $(cat "$pathsFile")
do
	# Remove trailing slash if any
	line=${line%/}
	# replace "/./" with "/"
	line=${line//.\//}
	#Determine path type
	if [[ -f "$line" ]]; then
		pathType=file
	elif [[ -d "$line" ]]; then
		pathType=folder
	else
		pathType=missing
	fi
	echo "  $pathType: $line"

	if [[ "$pathType" == "file" ]]; then
		extractFile $line
	elif [[ "$pathType" == "folder" ]]; then
		echo "    Looping through contents..."
		for f in $(git ls-files "$line")
		do
			echo "  Found $f in $line"
			extractFile "$f"
		done
    fi
done

rm -f "$restoreFile"