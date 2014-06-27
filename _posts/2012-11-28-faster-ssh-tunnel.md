---
title:  Faster tunneling of X11 over ssh
layout: post
author: Wolfgang Resch
---


X11 forwarding through an ssh tunnel can be slow. The following
command helps increase speed a bit (at the cost of a weaker
encryption):

```bash
ssh -XC -c blowfish host.some.where
```