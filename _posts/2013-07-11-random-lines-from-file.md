---
title:  How to pick a random subset of lines from file
layout: post
author: Wolfgang Resch
---


Here is a `perl` one-liner to pick a fraction x of lines from an input
file at random.  Note that the resulting file will not have a
predetermined but a stochastic number of lines.  The example shown
will pick a about 30% of all lines

```bash
perl -nle 'print $_ unless rand() >0.3' input_file
```

And here is an example of the expected results:

```bash
> for i in 1 2 3 4 5; do head -n 100 input_file | perl -nle 'print $_ unless rand() > 0.3' | wc -l; done
29
28
29
33
33
```

And if you'd like to pass the fraction of lines desired in the output
as a parameter you can do so like this:

```bash
perl -nle 'BEGIN {$f=shift} print $_ unless rand() > $f' 0.3 input_file
```

See [perlrun](http://perldoc.perl.org/perlrun.html) for more details.