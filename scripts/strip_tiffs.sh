#!/bin/bash
# strip_tiffs.sh
# $Id: strip_tiffs.sh 1947 2009-06-11 19:31:20Z mps $

PWD=`echo \`pwd\``
dirname=$1
tweak=modified

cd $dirname
mkdir -p ../${dirname}-$tweak
for file in `ls -1`; do
    echo "Processing $file..."
    convert $file -strip ../${dirname}-$tweak/$file
done
echo "Done."
echo
cd $PWD

