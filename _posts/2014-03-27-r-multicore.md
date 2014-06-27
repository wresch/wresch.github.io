---
title:  Parallel execution of R code with the multicore package
layout: post
author: Wolfgang Resch
---

There are a number of R packages that support a number of different
paradigms of parallel processing (see [High-Performance and Parallel
Computing with R](http://cran.r-project.org/web/views/HighPerformanceComputing.html)).
I'm going to briefly discuss the `multicore` package which essentially
forks multiple R processes on the same machine to execute functions in
parallel and thus helps to make use of all cores present on a machine.
multicore uses the cores option to determine how many processes to
spawn in parallel, unless otherwise specified.  If cores is not set,
then multicore will use all available cores.  Two important functions
in the package are

- `mclapply` - a parallel version of lapply
- `parallel/collect` - parallel executes R code in a forked process, collect collects the results

## mclapply

`mclapply` is a straight forward replacement for `lapply`, i.e. it
applies a function to a vector/list, but does so in parallel (see
below).  One thing to look out for is any code using random numbers.
Forked processes by default would share the random seed.  However, for
mclapply the default setting of `mc.set.seed=TRUE` results in different
random seeds in each forked subprocess.  `mclapply` returns a list of
ordered results when all subprocesses have finished.

```r
library(multicore)
r <- mclapply(1:10,
              FUN=function(x) {rnorm(100, mean=x)},
              mc.cores=2,
              mc.set.seed=TRUE
)
lapply(r, summary)
# [[1]]
#    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.
# -1.6680  0.2222  0.9518  0.8948  1.5850  2.9210
# [[2]]
#    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.
#  -0.220   1.244   1.950   1.964   2.652   4.474
# ...
```


## parallel/collect

`parallel(expr, ...)` starts evaluating expr in a forked process and
immediately returns a parallelJob object.  `collect(jobs, wait=TRUE,
...)` will then wait for the jobs to finish and collect their results.

```r
j1 <- parallel(rnorm(100, 1), name="mu1")
j2 <- parallel(rnorm(100, 2), name="mu2")
j3 <- parallel(rnorm(100, 3), name="mu3")
r2 <- collect(list(j1, j2, j3), wait=TRUE)
lapply(r2, summary)
# $mu1
#    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.
# -1.7250  0.4956  1.2400  1.1610  1.8640  3.7220
# $mu2
#    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.
# -0.7249  1.4960  2.2400  2.1610  2.8640  4.7220
# $mu3
#    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.
#  0.2751  2.4960  3.2400  3.1610  3.8640  5.7220
#
```

In previous versions `parallel` did not change the random seed in each
subprocess by default.  Now, however, changing the seed seems to be
the default:

```r
j1 <- parallel(rnorm(100, 1), name="mu1a")
j2 <- parallel(rnorm(100, 1), name="mu1b")
r2 <- collect(list(j1, j2), wait=TRUE)
lapply(r2, summary)
# $mu1a
#    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
# -2.8330  0.1761  1.0910  0.9456  1.7980  3.2160 
# 
# $mu1b
#    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
# -1.3690  0.5892  1.1280  1.1590  1.7110  3.6870 
```

Note the different medians.

*Update*: the `multicore` package is deprecated and will be replaced
by the `parallel` package.

```r
sessionInfo()
# R version 3.0.1 (2013-05-16)
# Platform: x86_64-pc-linux-gnu (64-bit)
# 
# locale:
#  [1] LC_CTYPE=en_US.UTF-8       LC_NUMERIC=C              
#  [3] LC_TIME=en_US.UTF-8        LC_COLLATE=en_US.UTF-8    
#  [5] LC_MONETARY=en_US.UTF-8    LC_MESSAGES=en_US.UTF-8   
#  [7] LC_PAPER=C                 LC_NAME=C                 
#  [9] LC_ADDRESS=C               LC_TELEPHONE=C            
# [11] LC_MEASUREMENT=en_US.UTF-8 LC_IDENTIFICATION=C       
# 
# attached base packages:
# [1] stats     graphics  grDevices utils     datasets  methods   base     
# 
# other attached packages:
# [1] multicore_0.2
# 
# loaded via a namespace (and not attached):
# [1] parallel_3.0.1 tcltk_3.0.1    tools_3.0.1   
```

 
	

