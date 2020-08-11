#!/usr/bin/env python3


import sys
import pandas
import argparse
import pdb

# Program defaults
from typing import Any

def eprint(*args, **kwargs):
    """print to STDERR"""
    print(*args, file=sys.stderr, **kwargs)


def verbose(message):
    if opt.verbose:
        eprint(message)

def debug(message):
    if opt.debug:
        eprint('#{}'.format(message))

opt_parser = argparse.ArgumentParser(description='Combine taxonomy and OTU table')

opt_parser.add_argument('-i', '--input',
                        help='OTU table filename',
                        required=True)
opt_parser.add_argument('-t', '--taxonomy',
                        help='Taxonomy table',
                        required=True)

opt_parser.add_argument('-o', '--output',
                        help='Taxonomy counts table',
                        )
opt_parser.add_argument('-s', '--separator',
                        help='Field separator',
                        default='\t')

opt_parser.add_argument('-v', '--verbose',
                        help='Print extra information',
                        action='store_true')

opt_parser.add_argument('-d', '--debug',
                        help='Print debug information',
                        action='store_true')

def getTax(key):
	return ";".join(taxonomy.loc[key])


opt = opt_parser.parse_args()

output = opt.output
if opt.output == None:
	output = opt.input + ".taxonomy.csv"


table = pandas.read_csv(opt.input, sep=opt.separator, header=0, index_col=0)

taxonomy = pandas.read_csv(opt.taxonomy, sep=opt.separator, header=0, index_col=0)

#asv2taxonomy =  {}
#for index, row in taxonomy.iterrows():
#	taxonomy_string=(";".join(row))
#	asv2taxonomy[index] = taxonomy_string
#table['taxon'] = table.index.map(asv2taxonomy)

table['Taxonomy'] = table.index.map(lambda x : getTax(x))
table = table.groupby("Taxonomy").sum()
table.to_csv(output)