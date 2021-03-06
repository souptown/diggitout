#!/bin/bash

# Each parameter after the first is the path to a folder or file that needs
# to be moved into a folder specified by the first parameter. Files in any
# folder that is passed in will be recursed over. When extracted, files will
# be compared with existing files of a similar base name and only
# copied if an md5 hash of the files differs from all existing of that
# base name. When copied, the file name, its version number, and its md5
# hash will be written to a properties file.

targetFolder=$1
manifest="$targetFolder/manifest.sh"
restoreFile=restore-extracted-files.sh
shift

# make sure the target folder exists
if [ ! -d $targetFolder ]; then
	mkdir -p "$targetFolder"
fi

# make sure the manifest file exists
if [ ! -f "$manifest" ]; then
	touch "$manifest"
	echo "#!/bin/bash" >> "$manifest"
fi

# Create bash file for restoring extracted files
rm -rf $restoreFile
echo "#!/bin/bash" >> $restoreFile

function getFileHash {
	md5sum -b $1 | cut -d ' ' -f1
}

function extractFile() {
	local FILE=$1
	local BASENAME=$(basename "$FILE")
	local EXTENSION="${BASENAME##*.}"
	local FILENAME_SANS_EXTENSION="${BASENAME%.*}"
	local CHECKSUM=$(getFileHash $FILE)
	# source the manifest file so we can look up checksums for existing files
	. "$manifest"
	local OTHER_VERSIONS_COUNT=$(ls -l -Q $targetFolder/$FILENAME_SANS_EXTENSION-*.$EXTENSION 2>/dev/null | wc -l)
	local found=no
	for i in $(seq 1 $OTHER_VERSIONS_COUNT)
	do
		local temp="$FILENAME_SANS_EXTENSION-$i.$EXTENSION"
		temp=${temp// /_}
		temp=${temp//-/_}
		temp=${temp//\./_}
		local found_hash=${!temp}
		if [ "$found_hash" == "$CHECKSUM" ]; then
			found=$i
		fi
	done
	if [ "$found" == "no" ]; then
		local VERSIONED_FILE_NAME="$FILENAME_SANS_EXTENSION-$OTHER_VERSIONS_COUNT.$EXTENSION"
		local propertyName=${VERSIONED_FILE_NAME// /_}
		propertyName=${propertyName//-/_}
		propertyName=${propertyName//\./_}
		cp $FILE $targetFolder/$VERSIONED_FILE_NAME
		echo "${propertyName}=$CHECKSUM" >> $manifest
		echo "cp $targetFolder/$VERSIONED_FILE_NAME $FILE" >> $restoreFile
	else
		echo "cp $targetFolder/$FILENAME_SANS_EXTENSION-$found.$EXTENSION $FILE" >> $restoreFile
	fi

	git rm -f "$FILE"
}

echo ""
echo ""
for parameter in "$@"
do
	if [[ -f "$parameter" ]]; then
		extractFile $parameter
	elif [[ -d "$parameter" ]]; then
		echo "$parameter is a folder"
	# else
 #    	echo "$parameter is an invalid path"
    fi
done
