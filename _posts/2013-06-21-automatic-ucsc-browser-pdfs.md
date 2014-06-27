---
title:  Automatically fetch PDFs of UCSC browser views for locations within a given session
layout: post
author: Wolfgang Resch
---


The script on the below ([current version on
bitbucket](https://bitbucket.org/wresch/fetch_browser_screenshots/overview))
will take a browser URL, a session URL (obtained by saving a session
to a file and copying the file to a site that is accessible by the
chosen browser), and a file listing positions (as browser strings,
i.e. chr:start-end to be obtained and will generate a PDF file for
each position.

The interesting part is essentially lines 60-68, where curl is used to
first fetch a URL that corresponds to the PDF/PS creation page. From
the html obtained from that URL, the path of the PDF for the browser
view is parsed and used to actually obtain the PDF.


```bash
#! /bin/bash
set -o pipefail
 
SCRIPT=$(basename $0)
USAGE="
NAME
    ${SCRIPT} - automatically fetch UCSC browser PDF files
 
SYNOPSIS
    ${SCRIPT} browser_url session_url position_file
 
DESCRIPTION
    Uses UCSC browser urls to automatically fetch PDFs for
    a list of regions provided in the position file.
    Saves pdf files to current directory.
    Respect usage limits imposed by the respective browsers.
 
ARGUMENTS
    browser_url
        base URL w/o protocol, e.g. niamssolexa.niams.nih.gov
    session_url
        complete URL pointing to a session file saved from
        the browser
    position_file
        one position in format chr:start-end per line for
        all the positions to be captured
 
DEPENDENCIES
    curl
    accessible UCSC browser or mirror
"
 
function usage {
    echo "$@" >&2
    echo "${USAGE}" >&2
    exit 1
}
 
function fail {
    echo "$@" >&2
    exit 1
}
 
 
# parse commandline
base="${1%/}"
[[ -z "${base}" ]] && usage "missing base url"
session="${2}"
[[ -z "${session}" ]] && usage "missing session url"
position_file="${3}"
[[ -z "${position_file}" ]] && usage "missing position file"
[[ -f "${position_file}" ]] || fail "${position_file} not found"
 
 
url1="http://${base}/cgi-bin/hgTracks?hgS_doLoadUrl=submit"
url1="${url1}&hgS_loadUrlName=${session}&hgt.psOutput=on"
 
while read pos
do
    echo "fetching ${pos}"
    pdfpath=$(curl -s "${url1}&position=${pos}" \
               | grep 'the current browser graphic in PDF' \
               | perl -ple 's:.*HREF="../trash(.*).pdf.*:/trash\1.pdf:')
    if [[ $? -ne 0 ]]
    then
    fail "  could not retrieve pdf url from ${url1}&position=${pos}"
    fi
    curl -s -o $(echo "${pos}" | tr ':-' '__').pdf "http://${base}/${pdfpath}"
done < ${position_file}
``` 
 