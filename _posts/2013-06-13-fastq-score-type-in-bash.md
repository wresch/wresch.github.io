---
title:  A fun (if hacky) way to determine fastq score types in bash
layout: post
author: Wolfgang Resch
---



Here are 2 fun little useful functions:

- `cat_file` checks that a (single !) file exists and then cats it
  whether or not it's gzipped.
- `fast_score_type` determines the score
  type of a fastq file based on the first 4000 reads in the file iff
  there are no line breaks in the sequence/quality fields.  It uses od
  which in this case dumps space separated ASCII values for each
  quality letter. Neat

```bash    
function log_fatal {
    echo "$@" >&2
    exit 1
}

function cat_file() {
    local f=${1}
    [[ ! -z "${f}" ]] || log_fatal "cat_file requires 1 argument (compressed or uncompressed file)"
    [[ -f "${fq}" ]]  || log_fatal "fastq file not found: ${fq}"
    # strip the gz if it's there
    fngz=${f%.gz}
    if [[ -f ${fngz} ]]
    then
        cat ${fngz}
    else
        gunzip -c ${f}
    fi
}

function fastq_score_type() {
    # NOTE: assumes that there are no line breaks allowed!
    local fq=${1}
    cat_file ${fq} \
        | head -n 20000 \
        | awk 'NR % 4 == 0' \
        | tr -d '\n' \
        | od -A n -t u1 -v \
        | awk 'BEGIN {min = 256; max = 0}
               {for (i=1; i <= NF; i++) {if ($i > max) max = $i; if ($i < min) min = $i}}
               END {if (max <= 75 && min < 59) print "phred33";
                    else if (max > 73 && min >= 64) print "phred64";
                    else if (min >= 59 && min < 64 && max > 73) print "solexa";
                    else print "unknown";}'
}
```