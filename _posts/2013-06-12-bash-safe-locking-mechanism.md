---
title:  Safe locking mechanism in bash to serialize access to some resource
layout: post
author: Wolfgang Resch
---


Say you have a makefile as part of a pipeline that tries to use `ssh` to
spin up a number of parallel jobs running on a cluster (see earlier
[post]({% post_url 2012-11-01-qsub-submit-jobs-from-makefile %})).
Running make in parallel mode with `-j` can
then result in many concurrent calls to ssh.  There may be, however, a
maximum number of concurrent ssh sessions, which is set by default to
10 (see `man ssh_config` for more details).  Any attempts to establish
more concurrent `ssh` sessions results in an error.  However, in this
scenario, each `ssh` session is very short (just long enough to `qsub` a
batch script), so we could just try to serialize access to `ssh` using
some locking mechanism.

One possible way to do this is using a global lock file. However, it's
easy to create a race condition when doing this. For example, the
following code has a race condition:

```bash	
if [[ ! -f ${SSH_LOCK_FILE} ]]
then
    touch ${SSH_LOCK_FILE}
    ...some code here...
    rm -f ${SSH_LOCK_FILE}
fi 
```

The problem here is that another process might create the lock file in
the short time between this code checking for the files existence and
actually creating it. So the creation of the lock file needs to be
made atomic. One possible solution (in bash) is to use `set -o
noclobber`, which means that redirection output to a file fails if the
file exists. So we can create the following functions to
create/release an atomic file lock in bash:

```bash 	
SSH_LOCK_FILE=${HOME}/.sshlock
function get_ssh_lock() {
    for i in {1..30}; do
        if ( set -o noclobber; echo "$$" > "${SSH_LOCK_FILE}") 2> /dev/null;
        then
            #this will cause the lock file to be deleted in case of other exit
            trap 'rm -f "${SSH_LOCK_FILE}"; exit $?' INT TERM EXIT
            return 0
        else
            usleep $(( 2000 * ($RANDOM % 100) + 500000 ))
        fi
    done
    echo "Failed to aquire lock ${SSH_LOCK_FILE} after 30 attempts" >&2
    return 1
}
```

This particular function attempts to acquire the lock file 30
times.  If it succeeds, it traps `INT`, `TERM` and `EXIT` signals to ensure
that the lock file is removed should something go wrong.  It
then returns 0 (OK).  If it fails to acquire the lock, it sleeps
between 0.5 and 0.7 s (some randomness to spread out the timers) and
tries again.  If it fails 30 times, it returns 1 (FAIL).

The following function releases the lock

```bash
function release_ssh_lock() {
    rm -f "${SSH_LOCK_FILE}"
    trap - INT TERM EXIT
}
```
 

These functions are then used like this:

```bash
if get_ssh_lock
then
    ssh -q remote_machine "some command"
    release_ssh_lock
fi
```

Another solution would be a locking directory instead of a file since
`mkdir` also operates atomically.

Neither of these is guaranteed to work over NFS if the processes are
running on different machines!