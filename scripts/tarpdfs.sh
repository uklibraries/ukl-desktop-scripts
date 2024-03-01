#!/bin/bash
#
#	proc_compress_win.sh
#
# Originally written by Kathryn Lybarger
# Modified by MLE Slone
# $Id: proc_tar.sh 2200 2009-08-11 13:51:12Z mps $

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
    foundaux=`find $real_dirname/$container -type d -name auxiliary | head -1`
    srcdir=`dirname $foundaux`
    #srcdir="$real_dirname/$container/$container-scan-1-"
    targetdir="$real_dirname/proc-$container"
    echo "Source: $srcdir"
    echo "Target: $targetdir"

    # we can be insane
    #sanity_check $srcdir
  
    cd $srcdir
    mkdir -p $targetdir
  
    echo "Packing up Modular PDF..."
    tar cf - --exclude=*.xml --exclude=*.tif ./export/*/$container | gzip -n > $targetdir/proc-modularpdf.tar.gz

# we want bigger files for HSM...
    #echo "Splitting Modular PDF into chunks..."
    #pushd $targetdir 2>/dev/null
    #split -b 268435456 -d proc-modularpdf.tar.gz proc-modularpdf-tgz-
    #popd 2>/dev/null
#
#    echo "NOT Removing big file..."
  
    echo "NOT Collecting cksums..."
    #/home/kathryn/digilab/scripts/bku_xml.sh $targetdir > $targetdir.xml
    #echo "Collecting checksums..."
    #checks.sh $targetdir | tee -a $targetdir.xml
}

# FIXME 
# DUPLICATE CODE -- move to include file
get_container() {
    input_container=`cygpath $1`
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
