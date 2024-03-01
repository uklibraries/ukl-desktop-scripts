#!/bin/bash
# checksum_scans.sh
# Wrapper to call bku_xml.sh and manufacture scan-foo.xml
#
# $Id: checksum_scans.sh 1472 2009-03-26 14:03:52Z mps $

#batch=$1
#dirname=`dirname $1`
#basename=`basename $1`
#
#/cygdrive/c/scripts/bku_xml.sh $batch > ${dirname}/scans-${basename}.xml

#/cygdrive/c/scripts/checks.sh $batch | tee -a ${dirname}/scans-${basename}.xml
#checks.sh $batch | tee -a ${dirname}/scans-${basename}.xml

for batch in $@; do
    if test ! -e $batch; then
        echo "Error: the directory"
        echo "    [ $batch ] "
        echo "does not exist.  Please check your directory and try again."
        exit
    fi

    dirname=`dirname $1`
    basename=`basename $1`
    checks.sh $batch | tee ${dirname}/scans-${basename}.xml
done
