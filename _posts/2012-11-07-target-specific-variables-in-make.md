---
title:  Target specific variables in makefiles
layout: post
author: Wolfgang Resch
---

Variables in makefiles are generally global.  However, target-specific
variables can be defined and are limited in scope to the rule they
were defined for and shadow global variables of the same name.  They
are define in a line immediatly before the rule listing the target,
followed by a colon and the variable definition:

For example, given the follwing makefile

```make

test = not_fnord

%.out:  test = $*
%.out: 
    echo "Content: $(test)" > $@
```

calling

```bash
make fnord.out
```

creates the file `fnord.out` with the following content:

```
Content: fnord
```

not

```
Content: not_fnord
```
