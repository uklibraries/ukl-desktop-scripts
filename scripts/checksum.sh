#!/bin/bash
# checksum.sh
# Wrapper to call bku_xml.sh and manufacture scan-foo.xml
#

batch=$1
dirname=`dirname $1`
basename=`basename $1`
#
#/cygdrive/c/scripts/bku_xml.sh $batch > ${dirname}/scans-${basename}.xml

/cygdrive/c/scripts/checks.sh $batch | tee ${dirname}/${basename}.xml

