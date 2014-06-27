---
title:  Background processes, nohup, and disowning your children
layout: post
author: Wolfgang Resch
---

For long(er) running jobs it's useful to run jobs in the background.
However, when a job is simply started in the background

```bash
> sleep 20 &
```

it becomes a child process of the current shell (see the PPID entry in the output from ps below; irrelevant lines removed).

```bash
> ps xlu
#   PID  PPID CPU PRI NI      VSZ    RSS WCHAN  STAT   TT       TIME COMMAND          USER    %CPU %MEM STARTED
# 34472 34320   0  31  0  2432748    540 -      S    s003    0:00.00 sleep 20         wresch   0.0  0.0  2:26PM
```

What happens to this child process when the current shell exits depends on the shell option `huponexit`

```bash
> shopt | grep huponexit
# huponexit          off
```

which seems to default to `off` on all the machines i checked.  This
means that when the parent shell is terminated, it does not send
`SIGHUP` to it's children and therefore the children continue to run.
If, however, `huponexit` is on, children will receive `SIGHUP` when the
parent shell is terminated and will therefore terminate themselves.
This can be avoided with the `nohup` utility.  `nohup` will connect stdin
to `/dev/null` and redirect stdout and stderr to nohup.out and ignore
`SIGHUP`.  In addition, the BSD `nohup` on OS X apparently also
disconnects the process from the controlling terminal because the
parent PID is now init (see below).  That does not seem to be the case
for GNU `nohup`, which maintains the process as a child of the current
terminal.

```bash
> nohup sleep 30 &
> ps xlu
#   PID  PPID CPU PRI NI      VSZ    RSS WCHAN  STAT   TT       TIME COMMAND          USER    %CPU %MEM STARTED
# 35472     1   0  31  0  2432748    540 -      S      ??    0:00.00 sleep 30         wresch   0.0  0.0  2:44PM
```

A way to disconnect a process from the current shell is to start it in
the background in a subshell. This will make the process a child of
PID 1 (init) on OS X (not shown) and Linux (shown below) - the child
process was disowned.

```bash
> (sleep 20 &)
> ps xl
# F   UID    PID   PPID PRI  NI    VSZ   RSS WCHAN  STAT TTY        TIME COMMAND
# 0 33634  18796      1  20   0 100908   600 hrtime S    pts/297    0:00 sleep 20
```

Since the process is now not a child of the shell, it will not be sent
`SIGHUP` when the shell terminates and therefore continues to run after
terminating the current shell, but for different reasons nohup-ed
processes do.