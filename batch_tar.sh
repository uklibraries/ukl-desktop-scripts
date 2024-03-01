#!/bin/bash
# batch_tar.sh
# $Id: batch_tar.sh 3465 2011-04-07 11:40:16Z mps $

usage()
{
  prog=`basename $0`
  echo "usage: $prog /path/to/batch"
  echo "help:  $prog --help"
}

helpu()
{
prog=`basename $0`
cat <<HELPU
Help for $prog:
This program assembles files in a given directory into compressed,
checksummed archives and produces a manifest listing the archives,
their bytecounts, and their checksums.  For example, if the directory
is "cookie", a manifest will be stored as "cookie/cookie-batch.xml".

The program takes the directory to be processed as its argument.

  $prog /cygdrive/f/batch_ky_20080310_kinks

Directory structure before running $prog:

  batch dir
    -> batch XML files
    -> newspaper dirs
       -> reel dirs
          -> target files (jp2 pdf tif xml)
	   -> date dirs

Directory structure after running $prog:

  batch dir
    -> batch XML tar
    -> newspaper dirs
       -> target tars from target files
       -> reel dirs
          -> date tars from date dirs

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

  # major variables
  UX_FULLPATH=`readlink -f $1`
  UX_DIR=`dirname $UX_FULLPATH`
  BATCH=`basename $UX_FULLPATH`
  WIN_DIR=`cygpath -d $UX_DIR`
  SUMXML=${UX_DIR}/${BATCH}-batch.xml
  
  # save our place
  PWD=`pwd`
  
  # cd to working copy
  cd $UX_FULLPATH
  
  # start checksum file
  start_sum_file $SUMXML
  
  # tar up top-level XML files
  foo=`ls *.xml`
  if test "x$foo" != "x"; then
    tar_and_sum_file $UX_DIR $BATCH/${BATCH}-batch.tgz $SUMXML $BATCH/*.xml
  else
    (cd $UX_DIR && echo "No batch XML files were found" > $BATCH/${BATCH}-nobatch.txt)
  fi
  
  # descend into $UX_FULLPATH
  # and build tars
  LOOK="/usr/bin/find * -maxdepth 0 -type d"
  for paper in `$LOOK`; do
    pushd $paper 2>/dev/null
    echo "-> $paper"
  
    for reel in `$LOOK`; do
      # tar up loose target files
      tar_and_sum_file $UX_DIR $BATCH/$paper/${BATCH}-${paper}-${reel}.tgz $SUMXML $BATCH/$paper/$reel/*.{jp2,pdf,tif,xml}
  
      # now work on each date
      pushd $reel 2>/dev/null
      echo "-> $paper -> $reel"
  
      for date in `$LOOK`; do
        tar_and_sum_file $UX_DIR $BATCH/$paper/$reel/${BATCH}-${paper}-${reel}-${date}.tgz $SUMXML $BATCH/$paper/$reel/$date
      done # with dates
      popd 2>/dev/null
    done   # with reels
    popd 2>/dev/null
  done     # with papers
  
  # end checksum file
  end_sum_file $SUMXML
  
  # now, where were we?
  cd $PWD
}


# tar and checksumming routines
start_sum_file ()
{
  xml=$1
  echo "<filegroup>"   > $xml # danger
  echo -e "\t<files>" >> $xml
}

end_sum_file ()
{
  xml=$1
  echo -e "\t</files>" >> $xml
  echo "</filegroup>"  >> $xml
}

tar_and_sum_file ()
{
  dir=$1 
  result=$2
  xml=$3
  shift 3
  files=$@

  # tar
  echo "*** Building $result"
  (cd $dir && tar --remove-files -zcvf $result $files)

  # checksum
  echo -e "\t\t<file>"                              >> $xml
  echo -e "\t\t\t<filename>$result</filename>"      >> $xml
  info=(`cksum $UX_DIR/$result`)
  echo -e "\t\t\t<bytecount>${info[1]}</bytecount>" >> $xml
  echo -e "\t\t\t<cksum>${info[0]}</cksum>"         >> $xml
  info=(`md5sum $UX_DIR/$result`)
  echo -e "\t\t\t<md5sum>${info[0]}</md5sum>"       >> $xml
  echo -e "\t\t</file>"                             >> $xml
}

main $@
