#!/usr/bin/perl -w
# help_verify.pl
# $Id: help_verify.pl 2127 2009-07-14 15:37:56Z mps $

use Carp;

# e.g. 
# help_verify.pl NDNP/Phase2/scans/mou scans-mou_18880224-19160630.xml

my (
    $hsm_directory,
    $checksum_file,
) = @ARGV;

my (
    $filename,
    $bytecount,
    $cksum,
    $md5sum,
);

my $hsmroot = '/users2/ewieg';

open my $checksum_fh, '<', $checksum_file
    or croak("$0: can't open $checksum_file for input: $!");

$/ = '</file>';


while(<$checksum_fh>) {
    undef $filename;
    undef $bytecount;
    undef $cksum;
    undef $md5sum;

    if ($_ =~ m,<filename>(.*)</filename>,) {
        $filename  = $1;
    }
    if ($_ =~ m,<bytecount>(.*)</bytecount>,) {
        $bytecount = $1;
    }
    if ($_ =~ m,<cksum>(.*)</cksum>,) {
        $cksum     = $1;
    }
    if ($_ =~ m,<md5sum>(.*)</md5sum>,) {
        $md5sum    = $1;
    }

    if (defined($filename)) {
        print "verify $hsmroot/$hsm_directory/$filename $bytecount $cksum $md5sum\n";
    }
}
