#!/bin/bash
# queue_for_hsm.sh
# $Id: queue_for_hsm.sh 3139 2010-06-28 18:05:00Z mps $

usage()
{
  prog=`basename $0`
  echo "usage: $prog <hsm-destination> <container>"
}

helpu()
{
prog=`basename $0`
cat <<HELPU
Run this program as
  $prog <hsm-destination> <container> 
This program appends the files in <container> to the HSM upload queue.
A file named "<container>/subdirectory/bar.tgz" will be copied to
the file "/users2/eweig/<hsm-destination>/subdirectory/bar.tgz" on HSM.

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

  if test ! -e $2; then
    # bad
    echo "Error: the upload directory"
    echo "   [ $2 ] "
    echo "does not exist.  Please check your directory and try again."
    echo
    exit
  fi

  # should not be needed
  # just in case, set proper execution path
  #/bin/bash //iarchives.ukpdp.org/storage/logs/export_path.sh
  
  PWD=`echo \`pwd\`` # using `pwd` leads to a mutable $PWD

  get_hsm_destdir $1 # sets $hsm_destdir
  get_container $2   # sets $real_dirname and $container

  # upload queue
  if [[ $OSTYPE == "cygwin" ]];
  then
    queuedir="/cygdrive/c/local"
  else
    queuedir="$HOME"
  fi
  queuefile="$queuedir/hsm-queue"

  # this is the core of the routine
  cd "$real_dirname/$container"
  LOOK=`find -mindepth 1 | sed -e "s,^\./,," | sort`

  CMD="make $hsm_destdir/$container"
  echo "Starting."
  echo "$CMD" >> $queuefile

  # the commands will be translated into
  # things like "ssh foo@bar mkdir -p dir"
  # or "scp file foo@bar:dest" by the program
  # that actually processes the queue
  for file in $LOOK; do
    if test -d $file;  then
      # if it's a directory, ensure that the directory exists
      CMD="make $hsm_destdir/$container/$file"
    else
      # otherwise, just copy the file
      CMD="send $real_dirname/$container/$file $hsm_destdir/$container/$file"
    fi
    echo "Adding [$file] to queue" # we like our scrolly screens
    echo "$CMD" >> $queuefile # foop
  done
  echo "Done."

  cd "$PWD"
}

# add routines here
get_container()
{
    if [[ $OSTYPE == 'cygwin' ]];
    then
        input_container=`cygpath $1`;
    else
        input_container=`readlink -f $1`
    fi
  #input_container=`cygpath $1`
  input_dirname=`dirname $input_container`
  pushd $input_dirname >/dev/null 
  real_dirname=`echo \`pwd\``
  popd >/dev/null
  container=`basename $input_container`
}

get_hsm_destdir()
{
  # hardcoded for now
  #eweig="/users2/ewieg" # sic
  eweig="/users2/eweig" # sic
  hsm_destdir="$eweig/$1"
}

main $@
