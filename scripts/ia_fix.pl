#!/usr/bin/perl -w
# ia_fix.pl
# $Id: ia_fix.pl 3391 2010-10-14 21:05:48Z mps $

use File::Basename;
use File::Find;

my (
	$directory,
    $default,
    $special,
) = @ARGV;

my %isok = ();

if (defined($special) and $special =~ m/^[0-9,]+$/) {
    foreach my $type (split ',', $special) {
        $isok{$type} = 1;
    }
}
elsif (defined($default) and $default =~ m/^[1-9][0-9]*$/) {
    $isok{$default} = 1;
}
else {
    $isok{'300'} = 1;
    $isok{'400'} = 1;
}

if (!defined($default) or $default !~ m/^[1-9][0-9]*$/) {
    $default = 300;
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
				# no news is good news
				# print "ok $file\n";
			}
			else {
				print "not ok $path ($xres, $yres), fixing to $default\n";
                $dir  = dirname( $file );
                $base = basename( $file, '.tif');
                $prefix = 'mps-';
                $tiff = $file; #"$dir/$prefix$base.tif";
                #$pdf  = "$dir/$prefix$base.pdf";
                #`cp $file $tiff`;
                `tiffset -s 296   2 $tiff 2>/dev/null`;
                `tiffset -s 282 $default $tiff 2>/dev/null`;
                `tiffset -s 283 $default $tiff 2>/dev/null`;
                bump_fixed();
                bump_bad();
			}
		}
	}
}
