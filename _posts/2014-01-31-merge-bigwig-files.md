---
title:  Merging bigwig files
layout: post
author: Wolfgang Resch
---

For visualization in the genome browser it's often useful to merge
(average) several bigwig files, for example to show the average of
several replicates as a single track in the browser.  This can be done
by merging bam files and creating a track from the merged bam files.
In that case, the bam files should probably be sampled so that each
replicate contributes equally to the final average.  And any
redundancy filtering may be problematic on the combined bam as
coverage might be very high.  Alternatively, the bigwig files
themselves can be merged using UCSC tools using the script
shown below.

[Download script](/assets/merge_bigwig.sh)

```bash
#! /bin/bash 
set -o pipefail

function usage {
    echo "NAME"
    echo "    merge_bigwig.sh - average bigwig files"
    echo "SYNOPSIS"
    echo "    merge_bigwig.sh [OPTIONS] outfile chrom_sizes bigwig1 bigwig2 [bigwig3 ...]"
    echo "DESCRIPTION"
    echo "    Takes multiple bigwig files and creates a single averaged"
    echo "    bigwig file. Creates an intermediate bedgraph file which"
    echo "    may be large."
    echo "        outfile:     name of averaged bigwig file"
    echo "        chrom_sizes: tab separated file listing sizes of chromosomes"
    echo "        bigwig:      two or more bigwig files to merge"
    echo "OPTIONS"
    echo "    -g  memory available for sort in GB [1]"
    echo "    -T  temp dir for sort [${TMPDIR:-/tmp}]"
    echo "    -h  display help message"
    exit 1
}
 
function fail {
    echo "$@" >&2
    exit 1
}

mem_gb=1
tmpdir=${TMPDIR:-/tmp}
while getopts ":g:T:h" opt; do
    case $opt in
        g)
        mem_gb=$OPTARG
        ;;
        T)
        tmpdir=$OPTARG
        ;;
        \?)
        echo -e "Invalid option: -$OPTARG\n\n" >&2
        usage >&2
        ;;
        :)
        echo -e "Option -$OPTARG requires an argumen\n\n" >&2
        usage >&2
        ;;
        h)
        usage
        exit 0
        ;;
    esac
done
shift $((OPTIND - 1))
mem_mb=$(awk "BEGIN {printf(\"%.0f\", $mem_gb * 1024)}")

out_bw=${1:-none}
shift
[[ "${out_bw}" != "none" ]] || usage >&2
 
genome=${1:-none}
shift
[[ "${genome}" != "none" ]] || usage >&2
[[ -f "${genome}" ]] || fail "Could not find '${genome}'"

[[ $# -gt 1 ]] || usage >&2

echo "OUTPUT FILE:       ${out_bw}"
echo "CHROM SIZES:       ${genome}"
echo "INPUT FILES:       $#"
echo "MEMORY FOR SORT:   $mem_gb GB = $mem_mb MB"
echo "TEMP DIR FOR SORT: $tmpdir"

for f in "$@"; do
    [[ -e $f ]] || fail "Could not find '${f}'"
    echo "    - ${f}"
done
 
module load ucsc || fail "Could not load UCSC module"

# calculate factor for normalization
n=$#
f=$(echo "1 / $n" | bc -l)
echo "NORM FACTOR: $f" >&2

# merge bigwig files; this creates a bedgraph file which
# is saved as a temporary file
tmp=$(mktemp ${tmpdir}/merged_bg.XXXX)
trap "rm -f ${tmp}" EXIT
export LC_ALL=C
bigWigMerge "$@" stdout \
    | awk -v f=$f 'BEGIN{OFS="\t"}{$4=f*$4; print}' \
    | sort -S ${mem_mb}M -T $tmpdir -k1,1 -k2,2n > ${tmp} \
    || fail "bigWigMerge failed"
 
# create new bigwig file from temporary bedgraph file
bedGraphToBigWig ${tmp} ${genome} ${out_bw} || fail "bedGraphToBigWig failed"
```

*Note*: this script makes use of the [Environment Module System](https://www.tacc.utexas.edu/research-development/tacc-projects/lmod). 
You may have to modify the script to work in your environment.

*Note*: this script was modified 2016-07-07 to include an extra sort step. It appears that
bigWigMerge outputs chromosomes in a sort order that bedGraphToBigWig does not accept. I'm
not sure if this is new behaviour for the UCSC tools or if this was always a bug in this script.
