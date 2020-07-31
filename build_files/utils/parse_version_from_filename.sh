#!/bin/bash
set -u

# The path for the downloaded blender binaries
filename=${1}
# Format: full, version, sha
format=${2:-"full"}

function read_blender_version() {
    local filepath=$1
    local versionformat=$2
    local filename
    filename=$(basename "$filepath")

    # Regex to extract version
    version_regex='blender-([0-9\.]+)-([a-f0-9]+)-.*'

    if [[ $filename =~ $version_regex ]]; then
        if [[ $versionformat == "release" ]]; then
            echo "${BASH_REMATCH[1]}"
        elif [[ $versionformat == "sha" ]]; then
            echo "${BASH_REMATCH[2]}"
        else
            echo "${BASH_REMATCH[1]}-${BASH_REMATCH[2]}"
        fi
        return 0
    fi

    # indicate failure if no regex has been found
    return 1
}

read_blender_version "${filename}" "${format}"
