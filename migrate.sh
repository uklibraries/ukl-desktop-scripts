#!/bin/bash
echo "don't run this"
exit

# Where are the METS files?
METSDIR=/cygdrive/t/mets_to_go_online/kek_1971014-20081215/mets

# Where are the images or other content files?
CONTENTDIR=/cygdrive/t/mets_to_go_online/kek_1971014-20081215/done

# Where should issue packages be built?
DESTDIR=/cygdrive/t/mets_to_go_online/kek_1971014-20081215/folders

# Where should reports go?
REPORTDIR=/cygdrive/t/mps/migrate

now=$(date +"%Y%m%d-%H%M%S")
report="$REPORTDIR/report-${now}.txt"
report_success="$report.success"
report_failure="$report.failure"

function report() {
    message=$1
    echo "$message" >> "$report"
}

function log_success() {
    message=$1
    echo "ok $message"
    echo "ok $message" >> "$report_success"
}

function log_failure() {
    message=$1
    echo "not ok $message"
    echo "not ok $message" >> "$report_failure"
}

for arg in $@; do
    id="$(basename "$arg" .xml)"
    mets="$METSDIR/$id.xml"

    # Test for common failure types

    if [ ! -f "$mets" ]; then
        log_failure "$id, $mets does not exist"
        continue
    fi

    xmllint "$mets" -noout
    ret=$?
    if [ $ret -ne 0 ]; then
        log_failure "$id, $mets failed to validate"
        continue
    fi

    content="$CONTENTDIR/$id"
    if [ ! -d "$content" ]; then
        log_failure "$id, $content does not exist"
        continue
    fi

    fcount=$(find "$content" -type f | wc -l | awk '{print $1}')
    if [ $fcount -eq 0 ]; then
        log_failure "$id, $content is empty"
        continue
    fi

    echo "ok $id, found both valid METS and content"

    # Now build the destination package

    dest="$DESTDIR/$id"
    mkdir -p "$dest"
    ret=$?
    if [ $ret -ne 0 ]; then
        log_failure "$id, could not create directory $dest"
        continue
    fi

    rsync -rvPO "$mets" "$dest"
    ret=$?
    if [ $ret -ne 0 ]; then
        log_failure "$id, could not copy METS to directory $dest"
        continue
    fi

    rsync -rvPO "$content" "$dest"
    ret=$?
    if [ $ret -ne 0 ]; then
        log_failure "$id, could not copy package content to directory $dest"
        continue
    fi

    log_success "$id, built package in $dest"
done

# Build final report, clearing temp files
:> "$report"
report "Migration report for $now"
report ""
report "Successful migrations:"
cat "$report.success" >> "$report"
report ""
report "Unsuccessful migrations:"
cat "$report.failure" >> "$report"
rm -f "$report.success"
rm -f "$report.failure"

echo "Migrations complete.  Report in $report"
