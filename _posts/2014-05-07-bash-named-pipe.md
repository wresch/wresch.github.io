---
title:  Bash named pipes and process substitution
layout: post
author: Wolfgang Resch
---

In bash, one can create named pipes (also called FIFOs).  They are
essentially a pipe that exists on the file system as a special device
and can be accessed by processes. Let's do an example.  In one
terminal create a named pipe and start feeding it some data

```bash
>  mkfifo npipe
>  ls -lh
total 32K
...
prw-rw-r--  1 wresch wresch    0 May  7 11:32 npipe
...
> cat > npipe
line 1
line 2
```

In a different terminal, start reading from the named pipe

```bash
> cat < npipe
```

Every time you hit enter on the sending side, the line will show up on
the receiving side until CTRL-D terminates the input on the sending
side, which will signal the receiver to terminate as well.  Named
pipes are blocking, i.e. the receiver will wait until data arrives.

The data flows through the kernel, so this only works on the same
machine, not across machines sharing the same filesystem.
 

One useful application of named pipes is process substitution (which
is bash specific).  Process substitution uses `<(cmd)` and `>(cmd)`. This
is used for example to provide input to a command that requires a
filename (won't read from stdin) from a command that writes to stdout:

```bash
> some_command <(zcat input.gz)
```

Under the hood, bash creates a named pipe, redirects the output of
zcat to it, and then gives some_command the file to read from.  That
way, no temporary file is created.
	
*This will fail if some_command needs to seek, for example to process
the input twice.  Since this is a named pipe, this is not possible.*

Another application is redirecting stdout and stderr to two different commands.

```bash
> some_command >(cmd1) 2> >(cmd2)
```