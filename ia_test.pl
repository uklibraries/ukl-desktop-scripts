#!/usr/bin/perl -w
# ia_test.pl
# $Id$

use File::Basename;
use File::Find;

my (
	$directory,
    $special,
) = @ARGV;

my %isok = ();

if (defined($special) and $special =~ m/^[0-9,]+$/) {
    foreach my $type (split ',', $special) {
        $isok{$type} = 1;
    }
}
else {
    $isok{'300'} = 1;
    $isok{'400'} = 1;
}

find(\&wanted, ($directory));
print_count();

{
	my $count = 0;
    my $bad   = 0;
	my $fixed = 0;

	sub bump_count {
		$count++;

		if ($count % 100 == 0) {
			#print "Checking TIFF #$count ($fixed fixed so far)\n";
		}
	}

	sub print_count {
		print "$count TIFFs examined";
        bump_bad(); $bad--;
        bump_fixed(); $fixed--;
        if ($bad > 0) {
            print ", $bad bad (";

            if (defined($fixed) and $fixed > 0) {
                print "$fixed";
            }
            else {
                print "Not";
            }
            print " fixed)\n"
        }
        else {
            print ".  No resolution problems found\n";
        }
	}

    sub bump_bad {
        $bad++;
    }

	sub bump_fixed {
		$fixed++;
	}
}

sub wanted {
	$file = $_;
    $path = $File::Find::name;
	if ($file =~ /\.tiff?$/) {
		bump_count();
		$tiffinfo = `tiffinfo $file 2>/dev/null`;
		if ($tiffinfo =~ /Resolution:\s*(\d+)\s*,\s*(\d+)/) {
			$xres = int($1);
			$yres = int($2);
            if ($isok{$xres} and $isok{$yres}) {
			#if (($xres == 300 or $xres == 400) and
			#    ($yres == 300 or $yres == 400)) {
				# no news is good news
				# print "ok $file\n";
			}
			else {
				print "not ok $path ($xres, $yres)\n";
                bump_bad();
			}
		}
	}
}
