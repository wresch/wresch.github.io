---
title:  Running a command with a timeout
layout: post
author: Wolfgang Resch
---

I needed to run a command with a timeout (basically to check
non-interactively whether passwordless access to a machine was set up)
and found the answer in this
[answer](http://stackoverflow.com/a/636148) on StackOverflow:

```bash
perl -e '$s = shift; $SIG{ALRM} = sub { print STDERR "Timeout!\n"; kill INT => $p }; \
         exec(@ARGV) unless $p = fork; alarm $s; waitpid $p, 0' 1 yes foo
```
	 
Another great PERL one liner.  Basically it sets an alarm, forks a
process, and then complains about Timeout if the process does not
finish in time.  The alarm will be inherited by the forked process.

 

I used this to check if password less login was working in a makefile
with the following script:

```bash
#! /bin/bash
perl -e '$s = 2; $SIG{ALRM} = sub { kill INT => $p; exit 1 };
         exec("ssh -q cluster_head_node \"hostname\"") unless $p = fork;
         alarm $s;
         waitpid $p, 0' &> /dev/null
if [[ $? -eq 0 ]];
then
    echo "OK"
    exit 0
else
    echo "FAIL"
    exit 1
fi
```
 

*Update*:  I realized you can also do this in bash:

```bash 
possibly_hanging_job & { sleep ${TIMEOUT}; eval 'kill -9 $!' &> /dev/null; }
```