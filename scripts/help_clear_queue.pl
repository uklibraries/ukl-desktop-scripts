#!/usr/bin/perl
# help_clear_queue.pl
# $Id: help_clear_queue.pl 1478 2009-03-26 16:10:38Z mps $

use Carp;
use Config;
use File::Copy;

my $os = $Config{osname};
my $queuefile;

if ($os eq 'linux') {
    $queuefile = $ENV{'HOME'};
}
else {
    $queuefile = '/cygdrive/c/local';
}
$queuefile .= '/hsm-queue';

my $wc = 0;
open my $file_fh, "<$queuefile" or croak("$0: can't open $queuefile: $!");
$wc++ while <$file_fh>;
close($file_fh);

#$wc += tr/\n/\n/ while sysread(FILE, $queuefile, 2 ** 16);
#$wc = `wc -l $queuefile 2>/dev/null`;
#($wc, @junk) = split('\s*', $wc);

my $items = "item";
if ($wc != 1) {
    $items .= 's';
}

if ($wc > 0) {
    print <<"WARNMSG";
WARNING:

Your queue [$queuefile] currently contains $wc $items.

WARNMSG

    my $still = 0;
    my $undecided = 1;
    my $response;
    my $delete = 0;

    while($undecided) {
        print "Are you sure you want to clear the queue? ";
        if ($still) {
            print "(Yes or No, please)";
        }
        print "\n\n] ";
        $response = <STDIN>;
        chomp($response);

        if ($response =~ m/^[Yy]/) {
            $undecided = 0;
            $delete = 1;
        }
        elsif ($response =~ m/^[Nn]/) {
            $undecided = 0;
            $delete = 0;
        }
        else {
        }
        print "\n";
        $still = 1;
    }

    if ($delete == 1) {
        my $queue_bak = join '_', $queuefile, 'bak', time;
        print "Okay, clearing the queue.\n";
        move($queuefile, $queue_bak);
        print "The queue is clear.\n";
    }
    else {
        print "Not clearing the queue.\n";
    }
}
else {
    print "The queue is clear.\n";
}
