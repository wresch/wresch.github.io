---
title:  CDE - a tool for reproducible research and application packaging using application virtualization
layout: post
author: Wolfgang Resch
---



The [CDE](http://www.pgbovine.net/cde.html) tool can help packaging
all files (executable, config, data, libraries, environment) required
to reproduce a set of commands into a single directory with can then
be compressed and shared with others. Given such a package, others can
exactly recreate the same steps without needing to worry about
dependencies or having to install anything. Currently this only works
on linux. To share across platforms, packages have to be included in a
minimal virtual machine (like tiny core linux).

As far as i understand it, cde intercepts system calls to keep track
of all files touched by any command preceded with the cde command and
includes them in the package.
