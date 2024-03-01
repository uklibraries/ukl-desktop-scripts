#!/bin/bash
# compress-drf.sh
# $Id: compress-drf.sh 2512 2010-01-11 20:27:40Z mps $

SERVER=\\\\iarchives.ukpdp.org\\storage6\\reels\\DRF\\color
reel=$1
SQM=$reel.sqm
NOW=`date --iso-8601=seconds`

echo "Downloading reel $reel from storage..."
robocopy $SERVER\\raws\\$reel C:\\local\\DRF\\$reel\\storage /S

echo 
echo "Compressing reel $reel..."

cd /cygdrive/c/local/DRF/$reel/storage
mkdir ../compressed
for tiff in *.tif; do
    echo "  $tiff"
    tiffcp -c lzw $tiff ../compressed/$tiff
    rm $tiff
done

echo 
echo "Building ScanQC manifest for reel $reel..."
cd ../compressed

cat > $SQM <<SQMINTRO
<?xml version="1.0" encoding="UTF-8"?>
<dbimport xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="dbimport">
<source created="$NOW">compress-drf.sh</source>
<metadataFiles/>
<globalProperties>
<property namespace="page:mods" name="import-adapter">com.iarchives.importer.builder.SimpleSQMBuilder
</property>
<property namespace="page:mods" name="source">ScanQC manifest
</property>
</globalProperties>
<images name="$reel">
<properties>
<property namespace="dbm" name="paths.raw">$SERVER\\$reel\\compressed
</property>
</properties>
SQMINTRO

WORKUNIT=1
MOD=0

for tiff in *.tif; do
    echo "  $tiff"
    MOD=$(( $MOD + 1))
    if (( "$MOD" > 20 )); then
        MOD=0
        WORKUNIT=$(( $WORKUNIT + 1))
    fi
    name=`basename $tiff .tif`
    echo "<image name=\"$name\" filename=\"$SERVER\\$reel\\compressed\\$tiff\" scope=\"$WORKUNIT\"/>" >> $SQM
done

cat >> $SQM <<SQMOUTRO
</images></dbimport>
SQMOUTRO

echo 
echo "Ready for test."
