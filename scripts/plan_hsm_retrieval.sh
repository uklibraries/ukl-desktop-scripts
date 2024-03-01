#!/bin/bash -e
# plan_hsm_retrieval.sh
#
# plan_hsm_retrieval.sh <remote_dir> <local_dir> <username>

if [ "$#" -ne 3 ]; then
    >&2 echo "Usage: $0 <remote_dir> <local_dir> <username>"
    exit
fi

remote_dir=$1
local_dir=$2
username=$3
server=hsm.uky.edu

queue=/cygdrive/c/local/hsm-queue
if [ ! -f "$queue" ]; then
    echo "Creating empty HSM queue file"
    :> "$queue"
fi

if [ "${remote_dir:0-1}" != "/" ]; then
    remote_dir="${remote_dir}/"
fi

remote_find="find \"$remote_dir\" -type f"
echo "Connecting to $server to find files under $remote_dir"
ct=0
for remote in $(ssh "$username@$server" "$remote_find"); do
    ct=$((ct+1))
    fragment=${remote#$remote_dir}
    target="$local_dir/$fragment"
    echo "fetch $remote $target" >> "$queue"
done
echo "Added $ct files to HSM queue"
