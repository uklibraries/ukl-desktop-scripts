#!/bin/bash
# fetch_file.sh
# $Id: fetch_file.sh 2358 2009-10-06 13:57:44Z mps $

usage()
{
  prog=`basename $0`
  echo "usage: $prog <hsm-filename> <local-directory>"
}

helpu()
{
prog=`basename $0`
cat <<HELPU
Run this program as
  $prog <hsm-filename> <local-directory>
For example,
  $prog NDNP/Phase1/batches/batch_ky_20070703_fleetwoodmac/sn87060032/00175046264/batch_ky_20070703_fleetwoodmac-sn87060032-00175046264-1904093001.tgz /cygdrive/e/from-hsm/mon_19090930
This program appends the given file to the HSM download queue.
When the queue is run (via process_hsm_queue.sh), the file will be downloaded
and copied to <local-directory>.

The file /cygdrive/c/local/hsm-queue contains the current queue.
HELPU
}

main()
{
  case "$1" in
    "")
      usage
      exit;;
    "-h" | "--help") 
      helpu
      exit;;
  esac

  if [ -z "$2" ]; then
    echo "Error: this program takes two arguments, but found only one"
    usage
    exit
  fi

  HSM_ROOT="/users2/ewieg"

  # upload queue
  if [[ $OSTYPE == "cygwin" ]];
  then
    queuedir="/cygdrive/c/local"
  else
    queuedir="$HOME"
  fi
  queuefile="$queuedir/hsm-queue"

  hsm_file=$1
  local_directory=$2
  mkdir -p $local_directory

  CMD="fetch $HSM_ROOT/$hsm_file $local_directory"

  echo "Adding [$hsm_file] to queue"
  echo "$CMD" >> $queuefile
}

main $@
