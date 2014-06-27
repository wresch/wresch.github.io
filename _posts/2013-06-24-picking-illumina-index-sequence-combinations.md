---
layout: post
title:  Picking illumina index sequence combinations
author: Wolfgang Resch
---

Illumina uses a short read with a separate sequencing primer to read
index sequences contained in adapter sequences.  If there is not
enough heterogeneity in the index sequences the read quality suffers.
This script generates combinations of indices that maximize
heterogeneity given a set of allowed indices and the number of samples
to be combined in a lane.

The script shown at the bottom ranks all possible combinations of n
index sequences from the given list of index sequences and displays
the best m combinations.  This is done by (1) determining what
fraction of all pairs of indices in a set has 4 or more differences
and (2) what fraction of positions in the index has close to optimal
sequence diversity (measured as being within 90% of maximal sequence
entropy).  Repository on bitbucket.

Given the following inputs

```
cat > setB.adapters <<EOF
1|ATCACG
3|TTAGGC
8|ACTTGA
9|GATCAG
10|TAGCTT
11|GGCTAC
20|GTGGCC
21|GTTTCG
22|CGTACG
23|GAGTGG
25|ACTGAT
27|ATTCCT
EOF
```

The script takes two arguments and reads the adapters from stdin:

```bash
#./goodadapter_combinations.py n m
#    n: number of samples (indices) per lane
#    m: number of highest ranking combinations to return
./good_adapter_combinations.py 6 4 < setB.adapters
```

and returns the following results to stdout:

```
***************************  ADAPTER SET  ****************************
1       ATCACG
3       TTAGGC
8       ACTTGA
9       GATCAG
10      TAGCTT
11      GGCTAC
20      GTGGCC
21      GTTTCG
22      CGTACG
23      GAGTGG
25      ACTGAT
27      ATTCCT
max sequence entropy at each cycle: 1.91829583405
top  sequence sets sorted by
  (1) the fraction of positions with entropy > 90% of max. entropy
  (2) the fraction of pairs with 4 or more differences
**********************************************************************
---------------
100% of positions had close to max. entropy
100% of pairs had more than 4 differences
---------------
3       TTAGGC
8       ACTTGA
10      TAGCTT
11      GGCTAC
22      CGTACG
27      ATTCCT
---------------
100% of positions had close to max. entropy
100% of pairs had more than 4 differences
---------------
3       TTAGGC
8       ACTTGA
10      TAGCTT
11      GGCTAC
22      CGTACG
23      GAGTGG
---------------
100% of positions had close to max. entropy
100% of pairs had more than 4 differences
---------------
3       TTAGGC
8       ACTTGA
9       GATCAG
10      TAGCTT
11      GGCTAC
22      CGTACG
---------------
100% of positions had close to max. entropy
 93% of pairs had more than 4 differences
---------------
3       TTAGGC
8       ACTTGA
10      TAGCTT
11      GGCTAC
22      CGTACG
25      ACTGAT
```


Below is the original version of the python script.  Current versions are available
from the [bitbucket repo](https://bitbucket.org/wresch/rank_good_index_combinations).

```python
#! /usr/bin/env python
"""
Usage: ./good_adapter_combinations.py n m < adapter_list
Arguments:
    n:  size of the desired adapter sets (i.e. how many samples to multiplex)
    m:  how many adapter combinations to show
Reads adapter list in format 'index nr|index sequence'
Ranks adapter combinations by (1) how many positions/cycles
have close to maximal sequnce entropy (90%) (2) how
many adapter pairs have 4 or more differences.
"""

import sys
import itertools
import array
import math

def entropy_ratio(seq_list, max_h):
    hf = []
    for s in itertools.izip(*seq_list):
        hf.append(entropy(s) / max_h)
    return hf

def entropy(s):
    nf = float(len(s))
    h = 0
    for nt in ["A", "C", "G", "T"] :
        f = s.count(nt) / nf
        if f > 0:
            h += - f * math.log(f, 2)
    return h

def dist(a, b):
    return sum(1 for a, b in itertools.izip(a, b) if a != b)

def pairwise_diff(seq_list):
    d = []
    for pair in itertools.combinations(seq_list, 2):
        d.append(dist(*pair))
    return d

def max_entropy(n):
    max_h = 0
    for s in itertools.combinations_with_replacement("ACGT", n):
        h = entropy(s)
        if h > max_h:
            max_h = h
    return max_h
 
def rank_good_combinations(kit, n, max_h, adapter_length):
    combo_list = []
    for combo in itertools.combinations(kit, n):
        seq_list = [b for a, b in combo]
        hf = entropy_ratio(seq_list, max_h)
        f_hf = sum(1 for x in hf if x > 0.9) / float(adapter_length)
        d = pairwise_diff(seq_list)
        f_d = sum(1 for x in d if x >= 4) / float(len(d))
        combo_list.append((f_hf, f_d, combo))
    combo_list.sort(key = lambda x: (x[0], x[1]))
    combo_list.reverse()
    return combo_list
 
 
if __name__ == "__main__":
    if (len(sys.argv) != 3):
        print >>sys.stderr, __doc__
        sys.exit(1)
    n = int(sys.argv[1])
    m = int(sys.argv[2])
    #read in the list of adapters from stdin
    adapters = [x.strip().split("|") for x in sys.stdin]
    adapter_len_set = set(len(b) for a, b in adapters)
    if len(adapter_len_set) != 1:
        print >>sys.stderr, "adapters of differing lenghts found in input"
        sys.exit(1)
    adapter_len = adapter_len_set.pop()
    max_h = max_entropy(n)
    print "{:*^70}".format("  ADAPTER SET  ")
    print "\n".join("{}\t{}".format(a, b) for a, b in adapters)
    print "max sequence entropy at each cycle: {}".format(max_h)
    print "top {} sequences sorted by ".format(m)
    print "  (1) the fraction of positions with entropy > 90% of max. entropy"
    print "  (2) the fraction of pairs with 4 or more differences"
    print "*" * 70
    ranked_combinations = rank_good_combinations(adapters, n, max_h, adapter_len)
    for i in range(m):
        c = ranked_combinations[i]
        print "-" * 15
        print "{:4.0%} of positions had close to max. entropy".format(c[0])
        print "{:4.0%} of pairs had more than 4 differences".format(c[1])
        print "-" * 15
        print "\n".join("{}\t{}".format(a, b) for a, b in c[2])
```
