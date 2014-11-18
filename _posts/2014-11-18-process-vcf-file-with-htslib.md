---
title:  Process a VCF file with htslib
layout: post
author: Wolfgang Resch
output: html_document
---

[Samtools and Bcftools](http://www.htslib.org/) are migrating to a single underlying
library for dealing with the various high-throughput sequencing data formats (SAM,
BAM, CRAM, VCF, BCF, and tabix). The library is called
[htslib](https://github.com/samtools/htslib).  As of now, documentation is limited
to comments in the code and examples can be found in the newer revisions of
samtools and bcftools using htslib.  Htslib has minimal dependencies (zlib) and
can easily be downloaded and installed.  The makefile creates a static and a
dynamic library.

I wanted to filter the [VCF file](ftp://ftp-mouse.sanger.ac.uk/REL-1410-SNPs_Indels/) from the
[Sanger mouse genome project](http://www.sanger.ac.uk/resources/mouse/genomes/). The
goal was to extract high quality SNPs for a single mouse strain in a tabular
format for further processing downstream (in my case create a mm10 genome incorporating
all the SNPs from one strain).

### Open VCF (or BCF) file and extract the number of samples present and the sequence names


```c
#include <stdio.h>  //puts and printf
#include <stdlib.h> //EXIT_FAILURE 
#include "vcf.h"

int main(int argc, char **argv) {
        if (argc != 2) {
                return EXIT_FAILURE;
        }

        // counters
        int nseq = 0;

        // open VCF/BCF file
        //    * use '-' for stdin
        //    * bcf_open will open bcf and vcf files
        //    * bcf_open is a macro that expands to hts_open
        //    * returns NULL when file could not be opened
        //    * by default also writes message to stderr if file could not be found
        htsFile * inf = bcf_open(argv[1], "r");
        if (inf == NULL) {
                return EXIT_FAILURE;
        }

        // read header
        bcf_hdr_t *hdr = bcf_hdr_read(inf);
        fprintf(stderr, "File %s contains %i samples\n", argv[1], bcf_hdr_nsamples(hdr));

        // report names of all the sequences in the VCF file
        const char **seqnames = NULL;
        // bcf_hdr_seqnames returns a newly allocated array of pointers to the seq names
        // caller has to deallocate the array, but not the seqnames themselves; the number
        // of sequences is stored in the int pointer passed in as the second argument.
        // The id in each record can be used to index into the array to obtain the sequence
        // name
        seqnames = bcf_hdr_seqnames(hdr, &nseq);
        fprintf(stderr, "Sequence names:\n");
        for (int i = 0; i < nseq; i++) {
                // bcf_hdr_id2name is another way to get the name of a sequence
                fprintf(stderr, "  [%2i] %s (bcf_hdr_id2name -> %s)\n", i, seqnames[i],
                       bcf_hdr_id2name(hdr, i));
        }


        // clean up memory
        if (seqnames != NULL)
                free(seqnames);
        bcf_hdr_destroy(hdr);
        bcf_close(inf);
        return 0;
}

```

With the comments this should be pretty self explanatory.  Internally, htslib represents
records as `bcf1_t` structures, which is why most the functions use the `bcf_` prefix.
The `bcf_` functions appear to be general and work with vcf and bcf format files. For
example, `bcf_open` will open vcf and bcf files (and actually any of the other formats
since it simply points to `hts_open`, the function that is used to open all file types.
Even though vcf uses 1-based indexing (i.e. first base is base 1), htslib internally uses
0-based indexing (i.e. bcf1_t::pos is 0 based).

### Iterate through all SNPs in file and extract data

Next, I want to iterate through all the SNPs for one particular mouse strain, filter
to high quality SNPs and output the data in tabular form.  It seems that this can
be accomplished with the `bcf_read` function, which will read the next record and
return 0 on success. When reading vcf files (as done here), it is necessary to
call `bcf_unpack` after read to populate the `bcf1_t::d` field.  However, each
of the function for fetching values from samples calles `bcf_unpack` if it hasn't
already been called, so no explicit call is required here.  Note that unpacking
the data for each gt for each sample is time comsuming for vcf data. Therefore,
if only a subset of samples is going to be considered, `bcf_hdr_set_samples`
can be used to limit which samples are parsed. It can be given a single sample or
a list of comma separated samples to include or exclude (prefix with `^`). It
can also take a filename for a file containing the information.

The `bcf_get_format_*()` functions extract data from the genotypes
for each record. This is subject to the restrictions imposed with
`bcf_hdr_set_samples`.  These functions allocate new memory if necessary. In
the case of the code here, they will only allocate on the first call and then
re-use the memory passed in, since all records contain the same number of
samples.

The actual filters applied here check for high quality, homozygous ALT calls
(FI == 1) with a genotype quality score > 20. See the
[sanger site](ftp://ftp-mouse.sanger.ac.uk/REL-1410-SNPs_Indels/README) for
more details.

```c
#include <stdio.h>
#include "vcf.h"
#include "vcfutils.h"

void usage() {
        puts(
        "NAME\n"
        "    03_vcf - High quality calls for single sample\n"
        "SYNOPSIS\n"
        "    03_vcf vcf_file sample\n"
        "DESCRIPTION\n"
        "    Given a <vcf file>, extract all calls for <sample> and filter for\n"
        "    high quality, homozygous SNPs. This will omit any positions\n"
        "    that are homozygous ref (0/0) or heterozygous.  The exact filter\n"
        "    used is\n"
        "        FI == 1 & GQ > 20 & GT != '0/0'\n"
        "        [NOTE: FI == 1 implies homozygous call]\n"
        "        \n"
        "    The returned format is\n"
        "        chrom pos[0-based]  REF  ALT GQ|DP\n"
        "    and can be used for Marei's personalizer.py\n"
                );
}



int main(int argc, char **argv) {
        if (argc != 3) {
                usage();
                return 1;
        }
        // counters
        int n    = 0;  // total number of records in file
        int nsnp = 0;  // number of SNP records in file
        int nhq  = 0;  // number of SNPs for the single sample passing filters
        int nseq = 0;  // number of sequences
        // filter data for each call
        int nfi_arr = 0;
        int nfi     = 0;
        int *fi     = NULL;
        // quality data for each call
        int ngq_arr = 0;
        int ngq     = 0;
        int *gq     = NULL;
        // coverage data for each call
        int ndp_arr = 0;
        int ndp     = 0;
        int *dp     = NULL;
        // genotype data for each call
        // genotype arrays are twice as large as
        // the other arrays as there are two values for each sample
        int ngt_arr = 0;
        int ngt     = 0;
        int *gt     = NULL;
        
        // open VCF/BCF file
        //    * use '-' for stdin
        //    * bcf_open will open bcf and vcf files
        //    * bcf_open is a macro that expands to hts_open
        //    * returns NULL when file could not be opened
        //    * by default also writes message to stderr if file could not be found
        htsFile * inf = bcf_open(argv[1], "r");
        if (inf == NULL) {
                return EXIT_FAILURE;
        }
        
        // read header
        bcf_hdr_t *hdr = bcf_hdr_read(inf);
        fprintf(stderr, "File %s contains %i samples\n", argv[1], bcf_hdr_nsamples(hdr));
        // report names of all the sequences in the VCF file
        const char **seqnames = NULL;
        // bcf_hdr_seqnames returns a newly allocated array of pointers to the seq names
        // caller has to deallocate the array, but not the seqnames themselves; the number
        // of sequences is stored in the int pointer passed in as the second argument.
        // The id in each record can be used to index into the array to obtain the sequence
        // name
        seqnames = bcf_hdr_seqnames(hdr, &nseq);
        if (seqnames == NULL) {
                goto error1;
        }
        fprintf(stderr, "Sequence names:\n");
        for (int i = 0; i < nseq; i++) {
                // bcf_hdr_id2name is another way to get the name of a sequence
                fprintf(stderr, "  [%2i] %s (bcf_hdr_id2name -> %s)\n", i, seqnames[i],
                       bcf_hdr_id2name(hdr, i));
        }

        // limit the VCF data to the sample name passed in
        bcf_hdr_set_samples(hdr, argv[2], 0);
        if (bcf_hdr_nsamples(hdr) != 1) {
                fprintf(stderr, "ERROR: please limit to a single sample\n");
                goto error2;
        }

        // struc for storing each record
        bcf1_t *rec = bcf_init();
        if (rec == NULL) {
                goto error2;
        }
        
        while (bcf_read(inf, hdr, rec) == 0) {
                n++;
                if (bcf_is_snp(rec)) {
                        nsnp++;
                } else {
                        continue;
                }
                // the bcf_get_format_int32 function does not appear to reallocate
                // the array it returns for each of the samples on each call. Just
                // needs to be freed in the end. First call to bcf_get_format_*
                // takes care of calling bcf_unpack, which fills the `d` member
                // of bcf1_t
                nfi = bcf_get_format_int32(hdr, rec, "FI", &fi, &nfi_arr);
                // GQ can be missing (".") in this VCF file; The htslib version
                // used right now does not return a negative value in that case,
                // so we can't check for it.  As it turns out, all homozygous
                // good quality calls for alt allele have GQ values, so it doesn't matter
                // here, but it's important to keep in mind.
                ngq = bcf_get_format_int32(hdr, rec, "GQ", &gq, &ngq_arr);
                ndp = bcf_get_format_int32(hdr, rec, "DP", &dp, &ndp_arr);
                ngt = bcf_get_format_int32(hdr, rec, "GT", &gt, &ngt_arr);
                if (fi[0] == 1 && gq[0] > 20 && gt[0] != 0 && gt[1] != 0) {
                        nhq++;
                        printf("chr%s\t%i\t%s\t%s\t%i|%i\n", seqnames[rec->rid],
                               rec->pos,
                               rec->d.allele[0],
                               rec->d.allele[bcf_gt_allele(gt[0])],
                               gq[0], dp[0]);
                }
                
        }
        fprintf(stderr, "Read %i records %i of which were SNPs\n", n, nsnp);
        fprintf(stderr, "%i records for the selected sample were high quality homozygous ALT SNPs in sample %s\n", nhq, argv[2]);
        free(fi);
        free(gq);
        free(gt);
        free(dp);
        free(seqnames);
        bcf_hdr_destroy(hdr);
        bcf_close(inf);
        bcf_destroy(rec);
        return EXIT_SUCCESS;
error2:
        free(seqnames);
error1:
        bcf_close(inf);
        bcf_hdr_destroy(hdr);
        return EXIT_FAILURE;
}

```
