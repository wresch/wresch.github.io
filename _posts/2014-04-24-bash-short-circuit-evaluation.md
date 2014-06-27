---
title:  Short circuit evaluation of conditionals in bash
layout: post
author: Wolfgang Resch
---

In bash an if statement can often be replaced by short circuit
evaluation of a conditional.  For example, to check for the existence
of a file you could use either

```bash
if  [[ -e "$filename" ]]; then
    echo "exists"
fi
```

or

```bash
[[ -e "$filename" ]] && echo "exists"
```

What happens in this case is that bash first executes the
command/expression on the left of the logical `and` (`&&`). If that
expression has a non-zero return value (i.e. it failed), then there is
no need to evaluate the right side of the `&&` because the overall exit
status is already known to be non-zero since both sides have to return
a success indicator for a logical and to return success.

The logical `or` (`||`) can be used similarly to only execute a
command if a test fails:

```bash
[[ -e "$filename" ]] || echo "could not find file"
```

The way this works is by again first evaluating the left side.  If the
left side is successful, then the logical `or` is already known to be
true and there is no need to execute the right side. The expression
results in a 0 exit status.  If the left side has a non-zero exit
status, then it is still necessary to evaluate the right side to
determine the exit status of the whole expression.  These two can be
combined:

```bash
[[ -e "$filename" ]] && echo "file exists" || echo "file does not exist"
```

These expressions can be useful for easy error checking/cleanup in
shell scripts.  For example

```bash
#! /bin/bash
set -o pipefail
 
function fail {
    rm -f ${tmp}*
    exit 1
}
 
module load bedops || fail
superE="$1"
rpa="$2"
motif="$3"
hs="$4"
foot="$5"
outf="$6"
 
tmp=$(mktemp temp/XXXX)
bedmap --echo --count --delim "\t" $superE $hs > $tmp || fail
bedmap --echo --count --delim "\t" $tmp $foot > ${tmp}.2 || fail
bedmap --echo --indicator --delim "\t" ${tmp}.2 $rpa > ${tmp}.3 || fail
bedmap --echo --echo-map-id --delim "\t" --multidelim "," ${tmp}.3 $motif > ${tmp}.4 \
    && mv ${tmp}.4 $outf \
    || fail
rm -f ${tmp}*
```

**Important caveat**: in the combined expression, if the middle
  command has a non-zero exit status, then both the middle and the
  rightmost command end up getting executed.