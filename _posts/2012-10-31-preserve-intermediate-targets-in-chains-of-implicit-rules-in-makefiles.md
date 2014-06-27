---
layout: post
title:  Preserve intermediate targets in chains of implicit rules in makefiles
author: Wolfgang Resch
---


in chains of implicit rules such as for example

```make
test.in:
    touch test.in
%.intermediate: %.in
    touch $@
%.out: %.intermediate
    touch $@
```

the command

```bash
make test.out
```

results in the following output

```
touch test.in
touch test.intermediate
touch test.out
rm test.intermediate
```

so `test.intermediate` is deleted since `make` considers it a
by-product. The `.SECONDARY` target can be used to instruct make to
keep such intermediate files. If the target is left without
pre-requisites, all intermediate files will be preserved. Otherwise a
list of files can be provided. As far as i know, patterns are not
allowed. The resulting make file then should look like this

```make
.SECONDARY:
test.in:
    touch test.in
%.intermediate: %.in
    touch $@
%.out: %.intermediate
    touch $@
```

to preserve all intermediate files. Or like this to preserve specific intermediate files:

```make
.SECONDARY: test.intermediate
test.in:
    touch test.in
%.intermediate: %.in
    touch $@
%.out: %.intermediate
    touch $@
```
