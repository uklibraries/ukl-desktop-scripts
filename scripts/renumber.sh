#!/bin/bash
# renumber.sh
# $Id: renumber.sh 2504 2009-12-22 20:05:41Z mps $

for DIR in $@; do
    SUBDIR="a"
    while [-e $DIR/$SUBDIR]; do
        SUBDIR=${SUBDIR}a
    done
    mkdir -p $DIR/$SUBDIR
    mv $DIR/*.tif $DIR/$SUBDIR
    cd $DIR/$SUBDIR
    COUNTER=0
    for file in `ls -1 *.tif`; do
        let COUNTER=$COUNTER + 1
        goal=`printf "../%04d.tif" $COUNTER`
        if [! -e $goal]; then
            mv $file $goal
        fi;
    done
    cd $DIR
    REMAINDER=`find $SUBDIR -type f | wc -l`
    if [ $REMAINDER -eq 0 ]; then
        rmdir $SUBDIR
    else
        echo "$REMAINDER files remain in $DIR/$SUBDIR."
    fi
done


