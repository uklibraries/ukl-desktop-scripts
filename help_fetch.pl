#!/usr/bin/perl -w
# help_fetch.pl
# $Id: help_fetch.pl 3470 2011-08-01 12:46:40Z mps $

use Carp;

# e.g. 
# help_fetch.pl NDNP/Phase2/scans/mou scans-mou_18880224-19160630.xml target

my (
    $hsm_directory,
    $checksum_file,
    $target,
) = @ARGV;

my (
    $filename,
);

my $hsmroot = '/users2/eweig';

open my $checksum_fh, '<', $checksum_file
    or croak("$0: can't open $checksum_file for input: $!");

$/ = '</file>';


while(<$checksum_fh>) {
    undef $filename;

    if ($_ =~ m,<filename>(.*)</filename>,) {
        $filename  = $1;
    }

    if (defined($filename)) {
        print "fetch $hsmroot/$hsm_directory/$filename $target/$filename\n";
    }
}
