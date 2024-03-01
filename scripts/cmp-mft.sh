#!/bin/bash
fst=$1
snd=$2
awk '{print $1}' "$fst/manifest-sha256.txt" | sort | sha256sum -t
awk '{print $1}' "$snd/manifest-sha256.txt" | sort | sha256sum -t
