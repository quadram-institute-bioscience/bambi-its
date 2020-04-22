#!/bin/bash

#file $(which usearch_10)
#/usr/bin/usearch_10: ELF 32-bit LSB executable, Intel 80386, version 1 (SYSV), statically linked, for GNU/Linux 2.6.24, BuildID[sha1]=fd94e2a833e2ab726d1dc9214e164d031429e154, stripped
#ubuntu@qi:~$ file $(which usearch)
#/home/ubuntu/bin/usearch: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, for GNU/Linux 2.6.24, BuildID[sha1]=58d782f0edb6061d09ca6fa7ee0a0a45c4bd5447, stripped
ERR=0

echo " * checking qiime"
qiime --version 2> /dev/null
if [ $? -gt 0 ]; then
	echo "  ERROR: Run this script with Qiime2 activted: qiime not found"
	ERR=$((ERR+1))
fi

echo " * checking 'usearch'"
U_PATH=$(which usearch)
if [ $? -gt 0 ]; then
	echo "  ERROR: usearch not found"
	ERR=$((ERR+1))
fi

VERSION=$(file usearch)
if [[ $VERSION =~ '32-bit' ]]; then
	echo "  ERROR: $U_PATH is 32-bit, but 64-bit is required"
	ERR=$((ERR+1))
else
	echo "  $U_PATH"
fi

if [[ $ERR -gt 0 ]]; then
	exit 1;
fi
