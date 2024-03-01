#!/bin/bash
# checks.sh
# $Id: checks.sh 3375 2010-08-12 14:25:34Z mps $

usage()
{
  prog=`basename $0`
  echo "usage: $prog <directory>"
}

helpu()
{
  prog=`basename $0`
  cat <<HELPU
This program produces checksums (bytecount, cksum, md5sum) for all
files in a given directory and sends the resulting XML to standard
output.  Invoke it with

  $prog <directory>

HELPU
}

main()
{
  sleepy=0
  case "$1" in
    "") 
      usage
      exit;;
    "-h"|"--help")
      helpu
      exit;;
    "-s"|"--sleep")
      sleepy=$2
      shift 2
  esac

  if test ! -e $1; then
      echo "Error: the directory"
      echo "    [ $1 ] "
      echo "does not exist.  Please check your directory and try again."
      exit
  fi

  PWD=`echo \`pwd\`` # bare `pwd` leads to mutable PWD
  get_container $1   # sets $real_dirname and $container
  cd $real_dirname
  #pushd $real_dirname 2>/dev/null

  # check for spaces
  for file in `find $container -type f | sort`; do
    if [ ! -e $file ]; then
        echo "File \"$file\" does not exist in $container.  Are there spaces in the name?"
        exit
    fi
    if echo $file | grep -E '[ "]' >/dev/null
    then
        echo "File \"$file\" has spaces.  Please rename it."
        exit
    fi
  done

  start_xml
  for file in `find $container -type f | sort`; do
    echo -e "\t\t<file>"
    echo -e "\t\t\t<filename>$file</filename>"
    info=(`cksum $file`)
    echo -e "\t\t\t<bytecount>${info[1]}</bytecount>"
    echo -e "\t\t\t<cksum>${info[0]}</cksum>"
    info=(`md5sum $file`)
    echo -e "\t\t\t<md5sum>${info[0]}</md5sum>"
    echo -e "\t\t</file>"

    # sleep?
    if [ $sleepy ]; then
      sleep $sleepy # sleep time is now
    fi
  done
  stop_xml
  
  cd $PWD
  #popd 2>/dev/null
}

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

start_xml()
{
  echo "<filegroup>"
  echo -e "\t<files>" 
}

stop_xml()
{
  echo -e "\t</files>" 
  echo "</filegroup>"
}

main $@

