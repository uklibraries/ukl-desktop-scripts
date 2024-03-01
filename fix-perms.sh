#!/bin/bash
dir=$1
find "$dir" -type d -print0 | xargs -0 -n 1 chmod 0775
find "$dir" -type f -print0 | xargs -0 -n 1 chmod 0664
