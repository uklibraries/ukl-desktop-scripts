#!/bin/bash
# process_hsm_queue.sh
# $Id: process_hsm_queue.sh 1365 2009-01-30 16:18:34Z mps $

usage()
{
  prog=`basename $0`
  echo "usage: $prog <username>"
}

helpu()
{
  prog=`basename $0`
  cat <<HELPU
Run this program as
  $prog <username>
This program processes queued HSM uploads via the <username>@hsm.uky.edu
account.

It reads actions from /cygdrive/c/local/hsm-queue
and writes completed actions to /cygdrive/c/local/hsm-done .
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

    # omit
  # just in case, set proper execution path
  #/bin/bash /cygdrive/c/scripts/export_path.sh

  # delegate to Perl
  #perl /cygdrive/c/scripts/help_process_hsm_queue.pl $@
  help_process_hsm_queue.pl $@
}

main $@
