#!/bin/bash
# checksum_all_scans.sh
# If we're going to have the drive all day, we 
# might as well checksum everything we can
#
# $Id: checksum_all_scans.sh 270 2008-07-02 20:48:49Z mps $

export PATH=/bin:/usr/bin:/usr/local/bin:$PATH

drive=`cygpath -u "$1"`
type=$2 # use drf or ndnp
scriptpath="/cygdrive/c/scripts"

pushd $drive
for drfbatch in `find ${type}* -maxdepth 0`; do
  if !(test -e $drive/scans-${drfbatch}.xml); then
    echo "Checksumming $drfbatch"
    $scriptpath/checksum_scans.sh $drive/$drfbatch
  fi
done
popd
