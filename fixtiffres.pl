#!/usr/bin/perl -w
# fixtiffres.pl
# $Id: fixtiffres.pl 2359 2009-10-12 21:08:19Z mps $

use File::Find;

my (
	$directory,
) = @ARGV;

find(\&wanted, ($directory));
print_count();

{
	my $count = 0;
	my $fixed = 0;

	sub bump_count {
		$count++;

		if ($count % 100 == 0) {
			print "Checking TIFF #$count ($fixed fixed so far)\n";
		}
	}

	sub print_count {
		print "$count TIFFs examined";
		if ($fixed > 0) {
			print ", $fixed fixed\n";
		}
		else {
			print ".  No resolution problems found\n";
		}
	}

	sub bump_fixed {
		$fixed++;
	}
}

sub wanted {
	$file = $_;
	if ($file =~ /\.tiff?$/) {
		bump_count();
		$tiffinfo = `tiffinfo $file 2>/dev/null`;
		if ($tiffinfo =~ /Resolution:\s*(\d+)\s*,\s*(\d+)/) {
			$xres = int($1);
			$yres = int($2);
			if (($xres == 300 or $xres == 400) and
			    ($yres == 300 or $yres == 400)) {
				# no news is good news
				#print "ok $file\n";
			}
			else {
				print "not ok $file ($xres, $yres), fixing\n";
				`tiffset -s 296   2 $file 2>/dev/null`;
				`tiffset -s 282 300 $file 2>/dev/null`;
				`tiffset -s 283 300 $file 2>/dev/null`;
				bump_fixed();
			}
		}
	}
}
