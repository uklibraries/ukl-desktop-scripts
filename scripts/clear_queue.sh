#!/bin/bash
# clear_queue.sh
# $Id: clear_queue.sh 1477 2009-03-26 16:05:55Z mps $

usage()
{
  prog=`basename $0`
  echo "usage: $prog"
}

helpu()
{
prog=`basename $0`
cat <<HELPU
This program clears the HSM upload queue.
HELPU
}

main()
{
  case "$1" in
    "-h" | "--help") 
      helpu
      exit;;
  esac

  # delegate to perl
  help_clear_queue.pl
}

main $@
