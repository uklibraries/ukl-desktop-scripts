#!/bin/bash
# doit.sh
# fix metadata

DIR=$1
FROM=$2
TO=$3

echo "Fixing $DIR ($FROM -> $TO)"
echo
pushd $DIR 2>/dev/null
for file in `ls -1 *.jp2 *.pdf`; do
    echo " * $file"
    sed -i.bak "s/$FROM/$TO/" $file
done

popd $DIR 2>/dev/null
echo "Done."
