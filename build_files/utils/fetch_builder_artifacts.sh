#!/bin/bash
set -u
shopt -s nocasematch

# Release can be for example: "2.90", "beta", "2.91", "alpha", ...
release=${1:-"beta"}
# operating system. Leave empty for all available downloads.
os=${2:-}
# Download destination path
destination=${3:-.}
basepath="$( cd "$(dirname "$0")"  && pwd )"

echo "Downloading Blender with version \"${release}\" to folder \"${destination}\"."

# Change into destination directory
if ! pushd "${destination}" 1> /dev/null; then
    echo "Cannot access folder \"${destination}\""
    exit 1
fi

# Fetch download links
download_links="$("${basepath}"/fetch_builder_artifacts_names.sh "${release}" "${os}")"
if [ $? -ne 0 ]; then
    echo "${download_links}" # Contains error message
    exit 1
fi

# Download the actual packages
for link in ${download_links};
 do
    echo "Downloading $(basename "${link}")"
    if ! curl -s --fail "${link}" -O; then
        echo "ERROR: Unable to download: ${link}"
        exit 1
    fi
done
echo "Finished downloading files to \"${destination}\"."

# Change back into previous folder
popd  1> /dev/null || exit 1
