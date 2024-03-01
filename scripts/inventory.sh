#!/bin/bash
# inventory.sh
# $Id: inventory.sh 2476 2009-12-11 18:54:24Z mps $

usage()
{
  prog=`basename $0`
  echo "Usage: $prog <path to drive>"
}

helpu()
{
prog=`basename $0`
cat <<HELPU
This program generates a directory-level manifest of a drive.

Example:

  $prog  /cygdrive/e

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

    drive=$1

    # pick up label
    driveletter=`basename $drive`
    thelabel=`cmd /c dir ${driveletter}: /w | sed -e "s///" | head -n 1 | perl -pe 's/.*Volume.*is\ (.*)$/\1/'`

    # manifest
    manifest="$drive/00_manifest.txt"
    mkdir -p "$drive/manifests"
    ddate=`date +%s`
    mv $manifest "$drive/manifests/manifest-$ddate.txt" 
    now=`date +%Y-%m-%d`
    echo "Generating manifest..."
    echo "label=$thelabel&newhistory=* $now: $thelabel found with contents:" | tee -a $manifest
    find $drive -type d 2>/dev/null | grep -v RECYCLER | grep -v "System\ Volume" | grep -v "^\.$" | grep -v "cygdrive/$driveletter$" | perl -pe 's#^$drive/##' | perl -pe 's#([^/]*)/#*#g; s#^(\*+)#\1 #' | grep -v "^\*\*\*\*\*" | tee -a $manifest

    # manifest to upload
    perl -pe 's#$#[:::]#' < $manifest > $manifest.upload

    # pick up username and passwd
    config="/cygdrive/c/local/filmeval/config/filmeval-config.txt"
    thelogin=`grep "user" $config | perl -pe 's/^\s*user\s*=\s*(.*)\s*$/\1/' | sed -e "s///"`
    thepasswd=`grep "pass" $config | perl -pe 's/^\s*pass\s*=\s*(.*)\s*$/\1/' | sed -e "s///"`

    # log in to filmeval
    #echo "Logging in to filmeval..."
    #cookies=/cygdrive/c/local/filmeval/config/filmeval-cookies.txt
    #curl -c $cookies -d "login=$thelogin&passwd=$thepasswd" http://filmeval.ukpdp.org/fe_login

    # submit the current contents
    echo "Submitting new history..."
    curl -c $cookies -b $cookies --data @$manifest.upload -L http://filmeval.ukpdp.org/fe_drive-update-history?login=$thelogin\&passwd=$thepasswd
    #echo $cmd
    #`$cmd`
}

main $@
