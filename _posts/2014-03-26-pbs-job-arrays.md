---
title:  PBS job arrays
layout: post
author: Wolfgang Resch
---

A quick notes on PBS job arrays (as implemented on our cluster), b/c i
could not find the documentation easily:

qsub has an option for creating job arrays (`-J`). Given a range, for
example 1-2, this results in 2 jobs being created as part of a job
array.  Each job will be called with `$PBS_ARRAY_INDEX` being set to the
corresponding number.  For example let's take this highly
sophisticated analysis script batch script

```bash
#! /bin/bash
echo "Greetings from job $PBS_ARRAY_INDEX in $PBS_JOBID run on $(hostname)"
```

Calling qsub with this qsub call

```bash
qsub -m n -J 1-2 -l nodes=1:c2 batch.sh
```

then results in this output

```
Greetings from job 1 in 5915539[1].biobos run on p298
Greetings from job 2 in 5915539[2].biobos run on p303
```

So `$PBS_ARRAY_INDEX` can be used to feed in different input files,
for example.