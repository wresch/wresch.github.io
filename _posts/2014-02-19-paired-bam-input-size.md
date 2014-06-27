---
title:  Insert size distribution from paired-end bam files
layout: post
author: Wolfgang Resch
---

The bam format contains a field for tracking the insert size of paired
end alignments:


>   9. TLEN: signed observed Template LENgth. If all segments are mapped
>   to the same reference, the unsigned observed template length equals
>   the number of bases from the leftmost mapped base to the rightmost
>   mapped base. The leftmost segment has a plus sign and the rightmost
>   has a minus sign. The sign of segments in the middle is
>   undefined. It is set as 0 for single-segment template or when the
>   information is unavailable.
> 
>    &mdash; from the [SAM specification v1.4](http://samtools.sourceforge.net/SAMv1.pdf)
 

To create a histogram of all template lengths below some maximal
length, one could simply pipe the sam format data into a script (awk,
perl, python), but for large bam files this is much too slow.  A
faster alternative is to use the samtools library.  The following
short program is also a template on how to use the high level samtools
API for the task of looping through all alignments in a bam file:

```c
#include <stdio.h>
#include "sam.h"
 
void usage(const char *msg) {
        fputs(msg, stderr);
        fputs("\nUSAGE: insert_size_hist bam_file\n", stderr);
}
 
int main(int argc, char **argv) {
        if (argc != 2) {
                usage("missing bam_file argument");
                return 2;
        }
        samfile_t *bam = samopen(argv[1], "rb", NULL);
        if (bam == NULL) {
                fprintf(stderr, "Could not open %s\n", argv[1]);
                return 2;
        }
        bam1_t *aln = bam_init1();
        int hist[1001] = {0};
        while (samread(bam, aln) >= 0) {
                const bam1_core_t *c = &aln->core;
                if ((c->flag & BAM_FPROPER_PAIR) == BAM_FPROPER_PAIR &&
                    (c->flag & BAM_FSECONDARY) != BAM_FSECONDARY &&
                    c->qual > 30 &&
                    c->isize > 0) {
                        if (c->isize > 1000) {
                                hist[1000]++;
                        } else {
                                hist[c->isize]++;
                        }
                }
        }
        int i = 0;
        for (i=0; i < 1001; i++) {
                printf("%i\t%i\n", i, hist[i]);
        }
        samclose(bam);
        return 0;
}
```

The bam file is opened with samopen and samread is used to load each
alignment.  For each alignment it checks that (1) the alignment is
from a proper pair and (2) is not secondary and (3) has a mapping qual
greater than 30 and (4) a positive TLEN.  Together these ensure that
each high quality pair alignment is considered exactly once.  Since I
ensured that no pairs with a tlen of greater than 1000 were reported
in the bam file, the same cutoff is hardcoded in this program, though
in reality this should be a configurable option given on the command
line (as should the quality cutoff).  The output contains a single
line for each possible length from 0 to 1000 (inclusive) and the
frequency with which the length was observed.
