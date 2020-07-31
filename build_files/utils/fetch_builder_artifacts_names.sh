#!/bin/bash
set -u
shopt -s nocasematch

# Release can be for example: "2.90", "beta", "2.91", "alpha", ...
release=${1:-"beta"}

# operating system. Leave empty for all available downloads.
os=${2:-}

BUILDER_DOMAIN=${BUILDER_DOMAIN:-"builder.blender.org"}
XMLLINT=${XMLLINT:-xmllint}

# check if xmllint binary is availble
if ! command -v "${XMLLINT}" > /dev/null; then
    echo "Error: Cannot find ${XMLLINT} binary. Please install the package."
    exit 1
fi
xmllint=$(command -v "${XMLLINT}")

# check if curl binary is availble
if ! command -v curl > /dev/null; then
    echo "Error: Cannot find curl binary. Please install the package."
    exit 1
fi
curl=$(command -v curl)

function parse_builder_html() {
    local release=${1}

    # strip leading "v" (v2.90.0)
    release=${release/"v"}

    # Check if we
    # - either can find the case insensitive string inside of the <a> (e.g. "Beta", "Alpha")
    # - or directly match the href (e.g. "2.90.0-72b422c1e101")
    xpath="
    //a[
        contains(
            translate(., 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),
            translate('${release}', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')
        )
        or
        contains(
            @href,
            '${release}'
        )
    ]/@href
    "
    ${curl} -s --fail "https://${BUILDER_DOMAIN}/download/" | ${xmllint} --html --xpath "${xpath}" - 2> /dev/null
}

# Fetch download links
download_hrefs="$(parse_builder_html "${release}")"
if [ $? -ne 0 ]; then
    echo "Error: Unable to find version \"${release}\" on \"${BUILDER_DOMAIN}\""
    exit 1
fi

links=${download_hrefs//href=}
links=${links//\"}
matches=0

# Search for the correct OS
for link in ${links};
 do
    # skip wrong OS (shopt nocasematch)
    if [[ ! $link =~ .*${os}.* ]]; then
        continue
    fi

    echo "https://${BUILDER_DOMAIN}${link}"
    ((matches++))
done

if [[ matches -lt 1 ]]; then
    echo "Error: Unable to find OS \"${os}\" in \"${links}\""
    exit 1
fi
