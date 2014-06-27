---
title:  Use xargs to execute jobs in parallel
layout: post
author: Wolfgang Resch
---


xargs can be used to construct and execute commands sequentially

```bash
seq 15 | xargs -n 1 echo
```

for example executes `echo` with arguments taken from stdin. In this
case using 1 (`-n`) space separated argument per invocation.

xargs can execute these commands in parallel:

```bash
seq 15 | xargs -n 1 -P 2 echo
```

in this case running a maximum of 2 processes (`-P` or `--max-procs`) at
any time. Of course, if executing in parallel, the results may be out
of order.

Now, if a file with one command per line already exists, each line can
be executed in parallel like so:

```bash
cat > test <<EOF
echo 1
echo 2
echo 3
echo 4
EOF

cat test | xargs -L 1 -I CMD -P 2 bash -c CMD
```

This works only if the commands don't contain quotes. Files like the
following example

```bash
cat > test <<EOF
mv "file 1" "file 2"
mv "file 2" "file 1"
echo -e "first\nsecond"
EOF
touch "file 1"
cat test | xargs -L 1 -I CMD bash -c CMD
```

result in errors or incorrect output.

In bash, this can be fixed by using `printf`'s `"%q"` format to escape
quotes in each command

```bash
cat test | while read -r i; do printf "%q\n" "$i"; done | xargs -L 1 -I CMD bash -c CMD
```

This will even work for special characters (see `\n` above), but line
continuations with backslash will fail.

More detail [here](http://coldattic.info/shvedsky/s/blogs/a-foo-walks-into-a-bar/posts/7)
.
