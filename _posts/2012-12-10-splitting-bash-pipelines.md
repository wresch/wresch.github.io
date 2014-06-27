---
title:  Splitting bash pipelines
layout: post
author: Wolfgang Resch
---

## Q

How can you take the same output of a single process and pipe it
through more than one other process?

## A

Using a bash-specific trick and tee:

```bash
cat foo | tee >(process1) >(process2) | process3
```

This works since `tee` can write what it reads on its `stdin` to several
files. This can be combined with the (bash only) process substitution
`>(process)`, which makes the process act like a file. This way
process1, process2, and process3 all work on the same input. This can
be useful, for example, when filtering a file by different criteria
and saving compressed output to different files (contrived example
below):

```bash
zcat foo.fq.gz | tee >(find_reads_with_adaptor | gzip -c > reads_with_adaptor.fq.gz) \
    | find_low_quality_reads | gzip -c > low_quality_reads.fq.gz
 ```