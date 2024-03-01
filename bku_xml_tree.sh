#!/bin/bash
#
#	bku_xml_tree.sh
#
# $Id: bku_xml_tree.sh 539 2008-08-26 20:17:23Z mps $

# just in case
/bin/bash //iarchives.ukpdp.org/storage/logs/export_path.sh

cd $1
filelist=`find -type f`

echo "<filegroup>"
echo -e "\t<files>"
for file in $filelist; do
	echo -e "\t\t<file>"
	echo -e "\t\t\t<filename>$file</filename>"
	info=(`cksum $file`)
	echo -e "\t\t\t<bytecount>${info[1]}</bytecount>"
	echo -e "\t\t\t<cksum>${info[0]}</cksum>"
	info=(`md5sum $file`)
	echo -e "\t\t\t<md5sum>${info[0]}</md5sum>"
	echo -e "\t\t</file>"
done
echo -e "\t</files>"
echo "</filegroup>"
