#! /bin/bash 
set -o pipefail

function usage {
    echo "NAME" >&2
    echo "    merge_bigwig.sh - average bigwig files" >&2
    echo "SYNOPSIS" >&2
    echo "    merge_bigwig.sh outfile chrom_sizes bigwig1 bigwig2 [bigwig3 ...]" >&2
    echo "DESCRIPTION" >&2
    echo "    Takes multiple bigwig files and creates a single averaged" >&2
    echo "    bigwig file. Creates an intermediate bedgraph file which" >&2
    echo "    may be large." >&2
    echo "        outfile:     name of averaged bigwig file" >&2
    echo "        chrom_sizes: tab separated file listing sizes of chromosomes" >&2
    echo "        bigwig:      two or more bigwig files to merge" >&2
    exit 1
}
 
function fail {
    echo "$@" >&2
    exit 1
}


out_bw=${1:-none}
shift
[[ "${out_bw}" != "none" ]] || usage
 
genome=${1:-none}
shift
[[ "${genome}" != "none" ]] || usage
[[ -f "${genome}" ]] || fail "Could not find '${genome}'"

[[ $# -gt 1 ]] || usage

echo "OUTPUT FILE:  ${out_bw}"
echo "CHROM SIZES:  ${genome}"
echo "INPUT FILES:  $#"

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
tmp=$(mktemp ./XXXX)
trap "rm -f ${tmp}" EXIT
bigWigMerge "$@" stdout \
    | awk -v f=$f 'BEGIN{OFS="\t"}{$4=f*$4; print}' > ${tmp} \
    || fail "bigWigMerge failed"
 
# create new bigwig file from temporary bedgraph file
bedGraphToBigWig ${tmp} ${genome} ${out_bw} || fail "bedGraphToBigWig failed"
