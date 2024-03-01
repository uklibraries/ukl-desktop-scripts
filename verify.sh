#!/bin/bash
# verify.sh
# $Id: verify.sh 2375 2009-11-12 21:12:46Z mps $

usage()
{
  prog=`basename $0`
  echo "usage: $prog <hsmpath> <checksums>"
}

helpu()
{
  prog=`basename $0`
  cat <<HELPU
Run this program as
  $prog <hsmpath> <checksums>
for example,
  $prog NDNP/Phase2/scans/mou scans-mou_18880224-19160630.xml
This program reads a checksum file and queues verification of upload.
HELPU
}

main()
{
  case "$1" in
    "")
      usage
      exit;;
    "-h"|"--help")
      helpu
      exit;;
  esac

  # upload queue
  if [[ $OSTYPE == "cygwin" ]];
  then
    queuedir="/cygdrive/c/local"
  else
    queuedir="$HOME"
  fi
  queuefile="$queuedir/hsm-queue"

  # delegate to Perl
  #perl /cygdrive/c/scripts/help_process_hsm_queue.pl $@
  help_verify.pl $@ >> $queuefile
}

main $@
