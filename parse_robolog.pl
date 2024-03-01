#!/usr/bin/perl
# parse_robolog.pl
#
# robocopy is documented at
# http://www.stevelu.com/TechnicalArticles/DevTools/1206.aspx
#
# $Id: parse_robolog.pl 539 2008-08-26 20:17:23Z mps $

use strict;

my $terminator = $/;
undef $/;

# robocopy log format:
#
# BLOCKS delimited by lines of 79 hyphens:
#   0. blank line
#   1. robocopy version ID
#   2. invocation
#   3. MAIN BLOCK
#   4. summary

my $buf         = <STDIN>;
my $indelimiter = '-' x 78;

my @blocks = split( $indelimiter, $buf );
my $i;

# MAIN BLOCK:
#
# There are three kinds of lines in the main block.
#
#   1. Error messages
#   2. Directory lines
#   3. File lines
#
# A sample string of error messages is
#
#   2008/05/02 17:22:21 ERROR 32 (0x00000020) Copying File \\iarchives.ukpdp.org\storage\root\projects\DRF\drf_19780520-19780524\xml\0121.xml
#   The process cannot access the file because it is being used by another process.
#   Waiting 30 seconds... Retrying...
#
# A sample directory line is
#
#  New Dir          0	\\iarchives.ukpdp.org\storage\root\projects\books\justice\rif\
#
# A sample file line is
#
#
#	    Newer     		    3849	0003.xml  0%  100%
#

# The line breaks up into
#
# STATUS ::= empty | 'New Dir' | 'New File' | 'Newer'
# NUMBER
# DIR/FILE
# JUNK   <-- this immediately follows DIR/FILE

my $main = $blocks[3];    # see list above
my $cr   = "";
my $lf   = "\n";
my $outdelimiter =
  "$cr$lf";               # we are working with a Windows log file, so use CR-LF
my @lines = split( $outdelimiter, $main );

my $line;
my @parsed = ();
my $parsed_line;
my @bits;
my $key;
my $tail;

my $keywords =
"MISMATCH|EXTRA File|New File|Newer|Older|Changed|Tweaked|Same|New Dir|No comment";
my $curdir;

# robocopy is documented at
# http://www.stevelu.com/TechnicalArticles/DevTools/1206.aspx
#
# Traverse the main block.
# Print out errors immediately.
# Clip-n-save massaged status lines.
foreach $line (@lines) {

    # skip blank lines
    if ( $line =~ /\S/ ) {

        # error lines begin in the first column
        if ( $line =~ /^\S/ ) {

            # it's an error - print out right away
            print $line . $outdelimiter;
        }
        else {

            # remove gunk
            $line =~ s/$cr.*//;

            # we need to keep a line long enough to update curdir
            # (if needed)

            if ( $line !~ m/$keywords/ ) {
                $line = 'No comment ' . $line;
            }

            # most lines have a keyword near the front
            if ( $line =~ m/($keywords)\s+\d+\s+(.*)/ ) {
                $key  = $1;
                $tail = $2;
            }
            else {
                $parsed_line = "Can't parse: [$line]";
            }

            # detect $curdir
            if ( $tail =~ m/\\/ ) {
                $curdir = $tail;

                # we know a dir exists if we get a file,
                # so the rest of this block is commented out
                #if ($key =~ /New/)
                #{
                #  push @parsed, "$key $tail";
                #}
            }
            else {

                # it's a file
                # print it out unless nothing happened
                if ( $key !~ /No\scom/ ) {
                    push @parsed, "$key $curdir$tail";
                }
            }

            #push @parsed, $parsed_line;
        }
    }
}

print $indelimiter . $outdelimiter;

# now print parsed lines
while (@parsed) {
    $line = shift @parsed;
    print $line . $outdelimiter;
}

