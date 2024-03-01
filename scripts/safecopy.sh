#!/bin/bash
# safecopy.sh -- play nice with HSM
#
# $Id: safecopy.sh 539 2008-08-26 20:17:23Z mps $
#
# sample invocation:
# safecopy.sh /cygdrive/e/batch_ky_20071010_GratefulDead /users2/eweig/NDNP1/scans/PhaseI/GratefulDead mpslon2

usage()
{
  prog=`basename $0`
  echo "usage: $prog /path/to/batch /users2/eweig/path/to/batch <username>"
}

helpu()
{
  prog=`basename $0`
  cat <<HELPU
This program uploads the contents of a directory to HSM in a polite 
manner, sleeping before the HSM cache completely fills and pausing
when HSM rejects connections.  Sample invocation:

  $prog /cygdrive/e/batch_ky_20071010_GratefulDead /users2/eweig/NDNP1/scans/PhaseI/GratefulDead mpslon2

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

  # just in case, set proper execution path
  /bin/bash //iarchives.ukpdp.org/storage/logs/export_path.sh
  
  SSH="/bin/ssh"
  SCP="/bin/scp"
  
  STOPFILE="/cygdrive/c/local/stopcopy" # create this file to pause safecopy
  flagpause=30                          # delete to restart
  
  seconds_per_minute=60
  
  maxfill=72           # maximum percentage to let the system fill before we pause
  resumefill=60        # how low should it be before we resume
  cktime="date +%s"    # number of seconds since the epoch
  ckmins=15            # how often to check
  let "ckinterval=$ckmins * $seconds_per_minute"
  
  SOURCE=$1
  UX_SOURCE=`cygpath -u $1`
  UX_SDIR=`dirname $UX_SOURCE`
  UX_SBAT=`basename $UX_SOURCE`
  
  TARGET=$2 # enter in Unix format
  UX_TARGET=$TARGET
  UX_TDIR=`dirname $UX_TARGET`
  UX_TBAT=`basename $UX_TARGET`
  
  USER=$3 # remote user
  
  PWD=`pwd` # where are we?
  
  failpause_mins=15
  let "failpause=$failpause_mins * $seconds_per_minute"
  
  nicepause=5 # time to pause between successful copies"
  
  cd $UX_SOURCE
  LOOK=`find -mindepth 1 | sed -e "s,^\./,,"`
  #     skip ..            remove ./ from front
  
  now=`$cktime`
  let "thn=$now-$ckinterval" # ensure that we check right away
  
  # go ahead and ensure target directory exists
  bad=1
  while (("$bad" > "0")); do
    bad=0
    echo "[$SSH $USER@hsm.uky.edu mkdir -p $UX_TARGET]"
    `$SSH $USER@hsm.uky.edu mkdir -p $UX_TARGET`
    if (("$?" > "0")); then
      bad=1
      echo "Can't yet create top directory, sleeping $ckmins minutes"
      sleep $ckinterval
    else
      echo "Ready to upload batch"
    fi
  done
  
  for file in $LOOK; do
    if test -d $file;  then
      # if it's a directory, ensure that the directory exists
      CMD="$SSH $USER@hsm.uky.edu mkdir -p $UX_TARGET/$file"
    else
      # otherwise, just copy the file
      CMD="$SCP $UX_SOURCE/$file $USER@hsm.uky.edu:$UX_TARGET/$file"
    fi
    
    bad=1
    while (("$bad" > "0")); do
      # don't proceed while STOPFILE exists
      know=0
      while(test -e $STOPFILE); do
        if (("$know" < "1")); then
          echo "Stopfile $STOPFILE detected, sleeping..."
  	know=1
        fi
        sleep $flagpause
      done
  
      # every so often, cache check
      tape=1
      while (("$tape" == "1" )); do
        now=`$cktime`
        tape=0
        let "gap=$now-$thn"
        echo "Seconds since last cache check: $gap"
        if [[ $gap -ge $ckinterval ]]; then
          echo "Cache check required"
          thn=$now
          fill=`chkfull.sh`
  	if [[ $fill -ge $maxfill ]]; then
  	  # too full
  	  tape=1
  
  	  # wait until cache fill drops to $resumefill
  	  while (("$tape" == 1 )); do
  	    echo "`$cktime`: System fill too high ($fill), waiting $ckmins minutes..."
  	    sleep $ckinterval
  
  	    # okay, now check again
  	    fill=`chkfull.sh`
  	    if [[ $fill -le $resumefill ]]; then
  	      tape=0
  	    fi
  	  done
  	else
  	  echo "System fill is $fill"
  	fi
        fi
      done
      echo "Okay, ready to copy $file"
  
      # try to copy file
      echo "[$CMD]"
      `$CMD`
  
      if (("$?" > "0")); then
        echo "Copy failed, waiting $failpause_mins minutes..."
        sleep $failpause
        echo "Trying again"
      else
        bad=0
        echo "Copy successful, sleeping $nicepause seconds"
        sleep $nicepause  # it's polite to wait a bit in any case
      fi
    done
  done
}

main $@
