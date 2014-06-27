---
title:  Passing command line arguments into R scripts
layout: post
author: Wolfgang Resch
---


If you'd like to run an R script for processing some data from the
command line (i.e. non interactively), it's often necessary to pass
some arguments into the script.  For example, lets write a simple
script to do column-wise statistics on files by simply reading the
file and calling summary:

```r	
fn <- "somefile.csv"
df <- read.table(fn, sep = ",", header = TRUE)
print(summary(df))
```

Now generate some example data and run the script from the shell

```bash
> perl -e 'print "col1,col2,col3\n"; for ($i=0;$i<20;$i++) \
           {print rand() . "," . rand() * 5 . "," . rand() * 10 . "\n"}' > somefile.csv
> R -q --no-save --no-restore --slave -f summary.R
#      col1              col2             col3      
# Min.   :0.04458   Min.   :0.1185   Min.   :0.4232 
# 1st Qu.:0.25550   1st Qu.:1.8638   1st Qu.:3.4375 
# Median :0.38139   Median :2.4246   Median :5.9120 
# Mean   :0.47104   Mean   :2.3656   Mean   :5.6726 
# 3rd Qu.:0.67615   3rd Qu.:3.2736   3rd Qu.:8.3637 
# Max.   :0.98758   Max.   :4.3326   Max.   :9.8417
```

Obviously a hard coded file name is not very useful.  Instead, let's
rewrite this to take a single argument:

```r
args <- commandArgs(trailingOnly = TRUE)
fn <- args[1]
df <- read.table(fn, sep = ",", header = TRUE)
print(summary(df))
```

The `trailing = TRUE` option results in `commandArgs` only returning
on the arguments after `--args`.

```bash
> R -q --no-save --no-restore --slave -f summary.R --args somefile.csv
#      col1              col2             col3       
# Min.   :0.01908   Min.   :0.1037   Min.   :0.01602 
# 1st Qu.:0.22552   1st Qu.:1.0515   1st Qu.:2.13243 
# Median :0.42952   Median :2.3641   Median :3.36631 
# Mean   :0.49441   Mean   :2.3710   Mean   :4.41240 
# 3rd Qu.:0.80786   3rd Qu.:3.7884   3rd Qu.:7.71034 
# Max.   :0.99459   Max.   :4.6230   Max.   :9.77731
```

Rscript makes this much easier:

```bash
> Rscript summary.R somefile.csv
```

And can also be used in a shebang line:

```r
#! /usr/bin/env Rscript
args <- commandArgs(trailing = TRUE)
fn <- args[1]
df <- read.table(fn, sep = ",", header = TRUE)
print(summary(df))
```

which can then be called directly

```bash
> chmod +x summary.R
> ./summary.R somefile.csv
```