#!/bin/bash
for file in *.xml; do
    xmllint -noout "$file" 2>/dev/null
    result=$?
    if [ "$result" -eq "1" ]; then
        echo "$file"
    fi
done
