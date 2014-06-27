---
layout: post
title:  Qsub submit jobs from makefile
---

As mentioned in an earlier post, `ssh` can be used to execute 
code on remote machines. This can help split pipelines up between
running on local code for less intensive computation and running code on
cluster nodes.  Our cluster is managed by PBS and jobs are submitted
with qsub.  The naive approach to running some pipeline steps as cluster
jobs then would look like this in a makefile:

```make
foo.sam: foo.fq
    echo "bowtie ...... mm9 foo.fq foo.sam" > temp.batch
    ssh -q cluster_head_node 'cd $(CURDIR) && /usr/local/pbs/bin/qsub -l nodes=1:c16 temp.batch'
```

However, this does not actually work since qsub exits immediately
after submitting the job before any output files actually have been
generated.  This results in problems with make which expects a target
file to exist once a rule finished executing.  The implementation of
`qsub` on our cluster provides the option to execute qsub in a
blocking mode.  `qsub -W block=true` will wait until the job
terminates and then return the jobs exit code:

    
```make
foo.sam: foo.fq
    echo "bowtie ...... mm9 foo.fq foo.sam" > temp.batch
    ssh -q cluster_head_node_node_node 'cd $(CURDIR) && /full/path/to/qsub -W block=true -l nodes=1:c16 temp.batch'
```

In this case the ssh call to qsub will wait for the complete job to
finish. Using this, it's even possible to submit qsub jobs in parallel
with make -j.  Note however that there may be limits on the number of
concurrent ssh connections to the cluster head node. An alternative that
avoids this issue (and does not depend on the ability of `qsub` to run
in blockig mode) makes use of sentinel files and some not so elegant
sleeping:

```make
foo.batch: foo.fq
    echo "bowtie .... mm9 foo.fq foo.sam && touch $@.DONE" > $@
foo.sam: foo.batch
    ssh -q cluster_head_node 'cd $(CURDIR) && /usr/local/pbs/bin/qsub -l nodes=1:c16 $<'
    while [[ ! -f "$<.DONE" ]]; do sleep 60; done
    rm $<.DONE
```
