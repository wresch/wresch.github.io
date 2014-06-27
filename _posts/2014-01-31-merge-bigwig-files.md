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
themselves can be merged using UCSC tools:

```bash
#! /bin/bash # USAGE:
merge_bw.sh outfile chrom_sizes bigwig1 bigwig2 ...
 
set -o pipefail
 
function fail {
    rm -f ${tmp}
    exit 1
}
 
module load ucsc || exit 1
out_bw=$1
shift
 
mm9=$1
shift
[[ -e ${mm9} ]] || exit 1
 
for f in "$@"; do
    [[ -e $f ]] || exit 1
done
 
# calculate factor for normalization
n=$#
f=$(echo "1 / $n" | bc -l)
echo "merging $n bigwig files" >&2
echo "  norm factor: $f" >&2

# merge bigwig files; this creates a bedgraph file which
# is saved as a temporary file
tmp=$(mktemp)
bigWigMerge "$@" stdout | awk -v f=$f 'BEGIN{OFS="\t"}{$4=f*$4; print}' > ${tmp} || fail
 
# create new bigwig file from temporary bedgraph file
bedGraphToBigWig ${tmp} ${mm9} ${out_bw} || fail
rm ${tmp}
```

*Note*: this script makes use of the [Environment Module System](http://modules.sourceforge.net/).