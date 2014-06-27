---
title:  Matching up homologous genes from different organisms with homologene
layout: post
author: Wolfgang Resch
---

[Homologene](http://www.ncbi.nlm.nih.gov/homologene) is an NCBI resource that constructs putative homology
groups across species based on NCBI's [gene](http://www.ncbi.nlm.nih.gov/gene) database.  The resource can
be queried interactively or through the [eutils API](http://www.ncbi.nlm.nih.gov/books/NBK25500/).  In addition, the
data can be downloaded from the HomoloGene [ftp](ftp://ftp.ncbi.nih.gov/pub/HomoloGene) site in a long form
table with the following columns:

    HID (HomoloGene group id)
    Taxonomy ID
    Gene ID
    Gene Symbol
    Protein gi
    Protein accession

For example, here are the rows for the homologene group containing
myc. Highlighted rows are _H. sapiens_ (taxid 9696) and _M. musculus_
(taxid 10090):


<table>
  <thead>
    <tr>
      <th>hid</th>
      <th>taxid</th>
      <th>geneid</th>
      <th>gene symbol</th>
      <th>protein id</th>
      <th>protein accession</th>
    </tr>
  </thead>
  <tbody>
    <tr class='tr-hl'>
      <td>31092</td>
      <td>9606</td>
      <td>4609</td>
      <td>MYC</td>
      <td>71774083</td>
      <td>NP_002458.2</td>
    </tr>
    <tr>
      <td>31092</td>
      <td>9598</td>
      <td>464393</td>
      <td>MYC</td>
      <td>218563723</td>
      <td>NP_001136266.1</td>
    </tr>
    <tr>
      <td>31092</td>
      <td>9544</td>
      <td>694626</td>
      <td>MYC</td>
      <td>218847750</td>
      <td>NP_001136345.1</td>
    </tr>
    <tr>
      <td>31092</td>
      <td>9615</td>
      <td>403924</td>
      <td>MYC</td>
      <td>153070853</td>
      <td>NP_001003246.2</td>
    </tr>
    <tr>
      <td>31092</td>
      <td>9913</td>
      <td>511077</td>
      <td>MYC</td>
      <td>114050751</td>
      <td>NP_001039539.1</td>
    </tr>
    <tr class='tr-hl'>
      <td>31092</td>
      <td>10090</td>
      <td>17869</td>
      <td>Myc</td>
      <td>71834865</td>
      <td>NP_034979.3</td>
    </tr>
    <tr>
      <td>31092</td>
      <td>10116</td>
      <td>24577</td>
      <td>Myc</td>
      <td>71834866</td>
      <td>NP_036735.2</td>
    </tr>
    <tr>
      <td>31092</td>
      <td>9031</td>
      <td>420332</td>
      <td>MYC</td>
      <td>73661206</td>
      <td>NP_001026123.1</td>
    </tr>
    <tr>
      <td>31092</td>
      <td>7955</td>
      <td>30686</td>
      <td>myca</td>
      <td>153946419</td>
      <td>NP_571487.2</td>
    </tr>
    <tr>
      <td>31092</td>
      <td>7955</td>
      <td>393141</td>
      <td>mycb</td>
      <td>41055786</td>
      <td>NP_956466.1</td>
    </tr>
  </tbody>
</table>

The following python script will create a table of all matches between
human and mouse, including instances where there are 1-to-n mappings,
rather than just 1-to-1 mappings

```python
import sys
import collections
 
# taxids
MOUSE = 10090
HUMAN =  9606
 
def d():
    return {"h": [], "m": []}
table = collections.defaultdict(d)
 
for i, line in enumerate(open(sys.argv[1])):
    if i == 0:
        continue
    hid, taxid, geneid, symbol, _, _ = line.split("\t")
    taxid = int(taxid)
    if taxid == MOUSE:
        org = "m"
    elif taxid == HUMAN:
        org = "h"
    else:
        continue
    table[hid][org].append(geneid)
print >>sys.stderr, "read %i homologenes" % len(table)
 
print "hid\tmouse\thuman"
skipped = 0
for hid, hgene in table.items():
    # omit the human genes that don't have a mouse entry
    # and mouse genes that don't have a human entry
    if len(hgene["h"]) == 0 or len(hgene["m"]) == 0:
        skipped += 1
        continue
    for mouse in hgene["m"]:
        for human in hgene["h"]:
            print "%s\t%s\t%s" % (hid, mouse, human)
print >>sys.stderr, "skipped %i entries" % skipped
```

In the case of human to mouse, HomoloGene build 67 had 17461 mappings
for 16784 homologous groups.