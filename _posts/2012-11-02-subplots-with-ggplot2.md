---
title:  Subplots with ggplot2
layout: post
author: Wolfgang Resch
---

Since ggplot2 is based on grid, subplots (more than one plot per
device) can be created the grid way with these two helper functions:

```r
subplot <- function(r, c) {
# select viewport from layout
#   used to do subplots
# Args:
#   r:  row
#   c:  column
# Returns:
#   viewport for plotting
 
    viewport(layout.pos.col=c, layout.pos.row=r)
}
 
vplayout <- function(r, c) {
# Set up grid layout for creating subplots
# Args:
#   r:  row
#   c:  column
# Returns:
#   viewport
  grid.newpage()
  pushViewport(viewport(layout=grid.layout(r, c)))
}
```

which can be used the following way (given two ggplot plot objects p1
and p2):

```r
vplayout(2, 1)
plot(p1, vp = subplot(1,1))
plot(p2, vp = subplot(2,1))
```

Any of the more advanced grid viewport magic can be used as well.  For
example [inset
plots)[http://learnr.wordpress.com/2009/05/08/ggplot2-plot-inside-a-plot/].
ggplot2 now also provides ways to add [plot annotations](https://github.com/hadley/ggplot2/wiki/Mixing-ggplot2-graphs-with-other-graphical-output)
itself.

###Update
This method does not ensure that axes are aligned.  A [newer post]({% post_url 2014-05-22-aligning-ggplot2-graphs %})
describes how to do this.
