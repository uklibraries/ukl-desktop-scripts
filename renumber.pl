#!/usr/bin/perl -w
# renumber.pl
# $Id: renumber.pl 2503 2009-12-22 19:44:31Z mps $

use Carp;
use File::Basename;

my (
    $target,
) = @ARGV;

my (
    $count,
    @queue,
    $filename,
    $directory,
    $extension,
);
$count = 0;
@queue = ();

if (-e $target and -d $target) {
    chdir $target;
    opendir (my $dh, ".")
        or croak("$0: can't open directory $target");
    @files = grep { !/^\./ } readdir($dh);
    closedir $dh;

    foreach $file (sort @files) {
        ($filename, $directory, $extension) = fileparse($file, ".tif");
        ++$count;
        $goal = sprintf("%04d", $count) . $extension;
        push @queue, $file;
        push @queue, $goal;
    }

    while ($#queue > -1) {
        $file = shift @queue;
        $goal = shift @queue;

        if ($file ne $goal) {
            if (! -e $goal) {
                rename $file, $goal;
            }
            else {
                push @queue, $file;
                push @queue, $goal;
            }
        }
    }
}
else {
    croak("$0: no such directory\n");
}
