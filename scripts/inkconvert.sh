#!/bin/bash
dir=$1
mkdir "${dir}-png"
for i in "$dir"/*.tif; do
    base=$(basename $i .tif)
    echo $base
    convert "$dir/$base.tif" -strip "${dir}-png/$base.png"
done
