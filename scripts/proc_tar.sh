#!/bin/bash
#
#	proc_compress_win.sh
#
# Originally written by Kathryn Lybarger
# Modified by MLE Slone
# $Id: proc_tar.sh 2379 2009-11-20 14:45:28Z mps $

usage() {
    prog=`basename $0`
    echo "Usage: $prog <container>"
}

#helpu() {
#prog=`basename $0`
#cat <<HELPU
#Help for $prog:
#HELPU
#}

main() {
    if [ "$#" != "1" ]; then
        usage
        exit
    fi
  
    conname=$1
    get_container $1 # sets $real_dirname and $container
    foundaux=`find $real_dirname/$container -type d -name export | head -1`
    echo "[dirname $foundaux]"
    srcdir=`dirname $foundaux`
    #srcdir="$real_dirname/$container/$container-scan-1-"
    targetdir="$real_dirname/proc-$container"
    echo "Source: $srcdir"
    echo "Target: $targetdir"

    # we can be insane
    #sanity_check $srcdir
  
    cd $srcdir
    mkdir -p $targetdir
  
    echo "Packing up auxiliary images..."
    tar cf - ./auxiliary | gzip -n > $targetdir/proc-aux.tar.gz
  
    echo "Packing up starman images..."
    tar cf - ./starman | gzip -n > $targetdir/proc-star.tar.gz
  
    echo "Packing up dlxs info..."
    tar cf - ./export/*/dlxs* ./export/*/pdf-for-web | gzip -n > $targetdir/proc-dlxs.tar.gz
    echo "Packing up Modular XML..."
    tar cf - --exclude=*.pdf --exclude=*.tif ./export/*/$container | gzip -n > $targetdir/proc-modularxml.tar.gz

    echo "Packing up Modular PDFs..."
    tar cf - --exclude=*.xml --exclude=*.tif ./export/*/$container | gzip -n > $targetdir/proc-modularpdf.tar.gz
  
    echo "Packing up miscellany..."
    tar cf - --exclude=web --exclude=export --exclude=auxiliary --exclude=starman . | gzip -n > $targetdir/proc-misc.tar.gz
  
    echo "Packing up web images $i..."
  
    pushd web
    lastbunch=`ls -1 *.tif | tail -1 | sed -e 's/[0-9][ab]*.tif//'`
    popd
  
    for i in `seq 0 $lastbunch`; do
    	num=`printf "%03d" $i`
    	if [ `ls -1 ./web/$num*.tif 2> /dev/null | wc -l` != "0" ]; then
    		echo "    bunch $i..."
    		tar cf - ./web/$num*.tif | gzip -n > $targetdir/web-$num.tar.gz
    	fi
    done
    echo "NOT Collecting cksums..."
    #/home/kathryn/digilab/scripts/bku_xml.sh $targetdir > $targetdir.xml
    #echo "Collecting checksums..."
    #checks.sh $targetdir | tee -a $targetdir.xml
}

# FIXME 
# DUPLICATE CODE -- move to include file
get_container() {
    input_container=`cygpath $1`
    echo "[dirname $input_container]"
    input_dirname=`dirname $input_container`
    pushd $input_dirname >/dev/null 
    real_dirname=`echo \`pwd\``
    popd >/dev/null
    container=`basename $input_container`
}

sanity_check() {
    cd $srcdir

    foo=`ls -1 ./export/* | wc -l`
    if [ $foo -gt 2 ]; then
        echo "WARNING: export directory contains material beyond dlxs and pdf-for-web."
        exit
    fi
  
    bar=`find ./export/*/dlxs | wc -l`
    if [ $foo == 0 ]; then
        echo "DANGER: dlxs directory appears to be empty."
        exit
    fi
}

#look_for_aux() {
#    my_container=$1
#
#    # 
#}

main $@
