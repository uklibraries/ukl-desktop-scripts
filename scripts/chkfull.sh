#!/bin/bash
# chkfull.sh -- check whether /users2 is full
#
# $Id: chkfull.sh 270 2008-07-02 20:48:49Z mps $

curl http://hpc.uky.edu/Stats/ 2>/dev/null | grep width | sed -e 's,.*:\ ,,; s,%.*,,' | tail -n 1
