#!/usr/bin/env python3

import pandas
import argparse
import os, os.path
import re 
import sys
import datetime
from pprint import pprint

def eprint(*args, **kwargs):
    """print to STDERR"""
    print(*args, file=sys.stderr, **kwargs)

def vprint(*args, **kwargs):
    if not opt.verbose:
        return 0 
    eprint(*args, **kwargs)


def clean_tax_string(string):
	"""
	Remove x__
	"""

	if re.search('.__', string): 
		return re.sub("^.__", "", string)
	else: 
		# if clean up needed return the same name 
		return string 


def load_taxonomy(filename, separator):
	try:
		with open(filename, 'r') as f:
			vprint(f"Reading {filename}")
			data = pandas.read_table(filename, sep=separator, index_col=0 )
			for col in data.columns: 
				data[col] = data[col].apply(clean_tax_string) 
				print(list(data[col].value_counts().index))
			pprint(data)
			return data
	except Exception as e:
		eprint(f"FATAL ERROR: Unable to open {filename}: {e}")



if __name__ == '__main__':

	# Script arguments
	opt_parser = argparse.ArgumentParser(description='Parse tabbed taxonomy file')

	opt_parser.add_argument('-c', '--csv', help="Input file is CSV (default: TSV)")
	opt_parser.add_argument('-i', '--input-file', help="Input file in tsv format (OTU, Domain, Phylum...)")

	opt_parser.add_argument('-v', '--verbose',
	                        help='Increase output verbosity',
	                        action='store_true')



	opt = opt_parser.parse_args()

	if opt.input_file == None:
		eprint("Missing input file")
		exit()
	
	separator='\t'
	if opt.csv != None:
		separator = ','
	load_taxonomy(opt.input_file, separator)



