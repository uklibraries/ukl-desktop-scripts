#!/bin/bash
# mkkeys
# $Id: mkkeys.sh 1360 2009-01-30 15:15:18Z mps $

usage()
{
  prog=`basename $0`
  echo "Usage: $prog <username>"
}

helpu()
{
prog=`basename $0`
cat <<HELPU
Help for $prog:
This program creates SSH keys on HSM so you can automate
uploads.

The program takes your username as an argument, and will
ask you for your password.

  $prog <username>

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
    
    username=$1
    remote="hsm.uky.edu"
    machine=`hostname`
    localkey="$HOME/.ssh/id_rsa"
    localpub="${localkey}.pub"

    # make sure we have a key to send
    if [[ ! -e $localkey ]];
    then
        ssh-keygen -t rsa -f $localkey
    fi

    # send key
    ssh $username@$remote mkdir -p -m 0700 /users2/$username/.ssh
    scp $localpub $username@$remote:.ssh/$machine.pub
    ssh $username@$remote "touch .ssh/authorized_keys; chmod 0600 .ssh/authorized_keys; cat .ssh/$machine.pub >> .ssh/authorized_keys"
}

# add routines here

main $@
