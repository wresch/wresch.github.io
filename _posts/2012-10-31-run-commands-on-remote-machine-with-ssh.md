---
layout: post
title:  Run commands on remote machine with ssh
author: Wolfgang Resch
---

{{page.title}}
================================================================================

Running a simple command on a remote machine with ssh is straight forward:

```bash
ssh biowulf 'echo $HOSTNAME'
```

However, watch out for shell expansion on the local machine (i.e. use either
`'echo $HOSTNAME'` or `"echo \$HOSTNAME"`).

This is useful, amongst other things, in makefiles where a target can
be created by executing a batch file on a remote machine as long as
it's ssh accessible. For example, given the following makefile

```make
foo.batch:
    @echo "echo \$$HOSTNAME" > $@
    @echo "pwd" >> $@
run: foo.batch
    ssh workhorse 'cd $(CURDIR) && bash $<'
```

make run on some machine with ssh access to `workhorse` will execute foo.batch
on workhorse and the target will wait for execution to finish.

The output should be

```
workhorse.somedomain.com
/path/to/pwd
```

Remember that this works best if the connection can be made without
the need to enter a password, for example using a key pair or kerberos
ticket.
