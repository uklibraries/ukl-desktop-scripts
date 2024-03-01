#!/usr/bin/perl
# process_hsm_queue.pl
# $Id: help_process_hsm_queue.pl 3466 2011-05-13 17:14:21Z mps $

# This program is invoked by process_hsm_queue.sh
# See that program for documentation and usage statement.
#
# Old tests were in revision 383.  Now using Test::More

use Carp;
use Config;
use File::Basename;
use File::Copy;
use File::Path;
#use Net::SSH::Perl;
use Test::More 'no_plan';

sub main {
    my ( 
        $username, 
    ) = @_;

    if ($username eq 'runtests') {
        runtests();
        exit;
    }

    local $| = 1;    # force flush

    my %seen;

    my $path = set_path();
    print "[\$path = $path]\n";

    my $home = set_home();
    set_username($username);

    my $met_log = "$home/hsm-done";
    my $set_log = "$home/hsm-queue";
    my $err_log = "$home/hsm-error";

    run_queue_forever(
        $met_log,
        $set_log,
        $err_log,
    );

    #print STDOUT "Congratulations, the upload queue is empty!\n";
}

{ # SLEEEEP!

    my $sleep_time = 0;
    my $sleep_bit  = 30;

    sub reset_sleep_time {
        $sleep_time = 0;
    }

    sub require_sleep {
        my (
            $amount,
        ) = @_;

        if ($amount > $sleep_time) {
            $sleep_time = $amount;
        }
    }

    sub sleep_if_required {
        if ($sleep_time) {
            $now = $time;
            $gap = $now - $thn;
            unless ( $gap > $sleep_time ) {
                print STDOUT "Sleeping $sleep_time seconds";
                while ($sleep_time) {
                    sleep $sleep_bit;
                    $sleep_time -= $sleep_bit;
                    print STDOUT '.';

                }
                print STDOUT "\n";
            }

        }


    }
}

{ # SSH
    my $username;

    #sub set_username {
    #    $username = shift @_;
    #    return get_username();
    #}

    sub get_username {
        if (defined($username)) {
            return $username;
        }
        else {
            # try using the Unix username
            my $attempt = getpwuid($<);
            return set_username($attempt);
        }
        return;
    }
}

sub run_queue_forever {
    my (
        $met_log, 
        $set_log,
        $err_log,
    ) = @_;

    my $pause = 5;

    FOREVER:
    #while (-e $set_log && -s $set_log) {
    while (2 == 2) {
        process_queue($met_log, $set_log, $err_log);
        say("Done with current entries, sleeping for $pause seconds...");
        sleep $pause;
        say("Checking $set_log for new entries...");
    }
    # shouldn't ever leave this loop

    say("Congratulations, $set_log looks empty to me!");
    return 0;
}

sub printable_version {
    my (
        $arg,
    ) = @_;
    chomp $arg;
    return $arg;
}

sub hsmgo {

    my $url = 'http://hpc.uky.edu/Stats/HSM/';

    open my $in, '-|', "curl $url 2>/dev/null"
        or croak("can't open $url: $!");

    local $/;

    my $content = <$in>;

    close $in
        or croak("can't close $url: $!");

    my $word;

    if ($content =~ m,<td>/users2</td>\s*<td>(.*)</td>\s*<td><div,) {
        print "found /users2\n";
        $word = $1;
    }

    return $word;
}

{   # CHECK INTO CACHE

    my $seconds_per_minute = 60;

    my $failpause_mins    = 0;
    my $failpause         = $failpause_mins * $seconds_per_minute;
    sub failpause {
        return $failpause;
    }

    my $cache_last_check_time;
    my $cache_check_interval   = 5 * 60; # 15 minutes
    sub cache_check_interval {
        return $cache_check_interval;
    }

    # set path
    my %path = (
        'cygwin' => '/cygdrive/c/scripts',
        #'linux'  => '/mnt/storage/logs',
        #'linux'  => '/home/mps/local/backup-scripts',
        'linux' => '/opt/pdp/scripts',
    );
    my $path;
    my $chkfull;

    my $cache_fill;

    #my $maxfill = $maxfill{$twig};

    my $maxfill    = 76;
    my $resumefill = 60;
    my $twig       = 0;

    sub get_path {
        if (!defined($path)) {
            set_path();
        }
        return $path;
    }

    sub get_chkfull {
        if (!defined($chkfull)) {
            set_chkfull();
        }
        return $chkfull;
    }

    sub set_chkfull {
        my $path = get_path();
        #print "[$path]\n";
        #$chkfull = "bash $path/chkfull.sh";
        $chkfull = "$path/chkfull.sh";
        return $chkfull;
    }

    sub set_path {
        my $osname = $Config{osname};

        if (exists($path{$osname})) {
            $path = $path{$osname};
        }
        else {
            $path = $path{cygwin};
        }
        return $path;
    }

    # When cache exceeds $maxfill, turn switch on
    # and keep it on until cache falls below $resumefill
    sub cache_overfull {
        if (cache_needs_checking()) {
            update_cache_fill();
        }
        return cache_overfull_helper($cache_fill);
    }

    sub cache_overfull_helper {
        my (
            $cache_fill,
        ) = @_;

        if ($cache_fill <= $resumefill) {
            $twig = 0;
            return $twig;
        }

        if ($cache_fill >= $maxfill) {
            $twig = 1;
            return $twig;
        }

        return $twig;
    }

    my $cache_never_checked    = 1;

    sub time_since_last_cache_check {
        return $cache_check_interval if $cache_never_checked;
        my $now = time;
        return $now - $cache_last_check_time;
    }

    sub cache_needs_checking {
        return 1 if $cache_never_checked;
        my $now = time;
        if ($now >= $cache_last_check_time + $cache_check_interval) {
            return 1;
        }
        else {
            return 0;
        }
    }

    sub update_cache_fill {
        $cache_fill = cache_fill();
    }

    sub cache_fill {
        my $now = time;
        #chomp($cache_fill = `$chkfull`);
        $cache_fill = 60;
        $cache_never_checked   = 0;
        $cache_last_check_time = $now;
        return $cache_fill;
    }

    sub wait_on_cache {
        my $fill;
        my $overfull;
        my $junk;

        while(!defined($overfull) or $overfull == 1) {
            say('Seconds since last cache check: ', time_since_last_cache_check());
            $overfull = 0;
            if (cache_needs_checking()) {
                say('Cache check required.');
                #$fill = cache_fill();
                #say("Current fill: $fill");
                $fill = hsmgo();
                $junk = cache_fill();
                say("Current status: $fill");
                if ($fill ne 'Open' and $fill ne 'Premigrate') {
                    say("System is writing to tape, locked, or otherwise unavailable");
                    $overfull = 1;
                    require_sleep( 4 * cache_check_interval() );
                    sleep_if_required();
                }
                #if ( cache_overfull() ) {
                #    say("System fill too high ($fill)");
                #    $overfull = 1;
                #    require_sleep( cache_check_interval() );
                #    sleep_if_required();
                #}
            }
        }
     }
}

{   # STOPFILE AND FRIENDS
    my $home;
    my $stopfile;

    sub get_home {
        if (!defined($home)) {
            set_home();
        }
        return $home;
    }

    sub set_home {
        if ($Config{osname} eq 'linux') {
            $home = $ENV{'HOME'};
        }
        else {
            # assume cygwin
            $home = '/cygdrive/c/local';
        }
    }

    sub get_stopfile {
        if (!defined($stopfile)) {
            set_stopfile();
        }
        return $stopfile;
    }

    sub set_stopfile {
        if (!defined($home)) {
            set_home();
        }
        $stopfile = "$home/stopcopy";
        return $stopfile;
    }

    sub destroy_stopfile {
        if (!stopfile_exists()) {
            return 1;
        }

        my $file = get_stopfile();

        unlink $file 
          or croak("$0: can't unlink $file: $!");
        return !stopfile_exists();
    }

    sub stopfile_exists {
        if (-e get_stopfile()) {
            return 1;
        }
        return 0;
    }

    sub create_stopfile {
        if (stopfile_exists()) {
            return 1;
        }

        my $file = get_stopfile();

        open my $stop_fh, ">$file"
          or croak("$0: can't open $file for output: $!");
        close $stop_fh;
        return stopfile_exists();
    }
}

{   # PERFORM TASKS
    my %routine;
    my $errlog_fh;
    my $current_goal;
    my $ssh   = 'ssh';
    my $scp   = 'scp';
    my $mkdir = 'mkdir -m 0775 -p';
    my $username;

    $routine{'make'} = sub {
        my (
            $directory,
        ) = @_;

        if (!defined($directory)) {
            complain_misformed();
            return;
        }
        else {
            my @cmd = ( $ssh, "$username\@hsm.uky.edu", "umask 0002; $mkdir $directory" );
            say('[', join(' ', @cmd), ']');
	    my $result = system(@cmd);
	    system( $ssh, "$username\@hsm.uky.edu", "chmod 0775 $directory" );
	    return $result;
        }
    };

    $routine{'verify'} = sub {
        #print "verify $hsmroot/$hsm_directory/$filename $bytecount $cksum $md5sum\n
        my (
            $file,
            $bytecount,
            $cksum,
            $md5sum,
        ) = @_;

        my $home = get_home();
        my $cksum_file = "foo.txt";

        # remote cksum
        say("Running remote cksum on $file");
        my @cmd = ( $ssh, "$username\@hsm.uky.edu", "cksum $file > ~/$cksum_file" );
        system(@cmd);



        # fetch cksum
        say("Fetching result");
        my @cmd = ( $scp, "$username\@hsm.uky.edu:$cksum_file", "$home/$cksum_file" );
        system(@cmd);

        open my $cksum_fh, '<', "$home/$cksum_file"
            or croak("$0: can't open $home/$cksum_file for input: $!");

        # interpret cksum
        my $line = <$cksum_fh>;

        my (
            $remote_cksum,
            $remote_bytecount,
            @junk
        ) = split('\s+', $line);

        open my $log_fh, '>>', "$home/hsm-verify"
            or croak("$0: can't open $home/hsm-verify for (potential) appending: $!");

        if ($remote_bytecount != $bytecount) {
            say("BAD: Expected bytecount $bytecount, got $remote_bytecount");
            print $log_fh "$file: expected bytecount $bytecount, got $remote_bytecount\n";
        }
        elsif ($remote_cksum != $cksum) {
            say("BAD: Expected cksum $cksum, got $remote_cksum");
            print $log_fh "$file: expected cksum $cksum, got $remote_cksum\n";
        }
        else {
            say("cksum and bytecount tests passed");
        }

        close $cksum_fh;
        close $log_fh;
        return 0;
    };

    $routine{'send'} = sub {
        my (
            $source,
            $target,
        ) = @_;

        if(!defined($source) or !defined($target)) {
            complain_misformed();
            return;
        }
        elsif (lc($source) =~ /thumbs/) {
            say("File $source looks like Thumbs.db, skipping");
            return 0; 
        }
        else {
            say("Sending $source -> $target");
            my $qtarget = $target;
            # quote parens
            $qtarget =~ s/([()])/\\$1/g;
            my @cmd = ( $scp, $source, "$username\@hsm.uky.edu:$qtarget" );
	    my $result = system(@cmd);
	    system( $ssh, "$username\@hsm.uky.edu", "chmod 0664 $qtarget" );
	    return $result;
        }
        say("Can't happen");
        return;
    };

    $routine{'fetch'} = sub {
        my (
            $source,
            $target,
        ) = @_;

        if (!defined($source) or !defined($target)) {
            complain_misformed();
            return;
        }

        mkpath(dirname($target));

        say("Fetching $source -> $target");
        my $qsource = $source;
        # quote parens
        $qsource =~ s/([()])/\\$1/g;
        my @cmd = ( $scp, "$username\@hsm.uky.edu:$qsource", $target );
        return system(@cmd);
    };

    sub start_errlog {
        my (
            $errlog,
        ) = @_;

        open $errlog_fh, ">>$errlog"
          or croak("$0: can't open error log $errlog for output: $!");
    }

    sub stop_errlog {
        close $errlog_fh
          or croak("$0: can't close error log: $!");
    }

    sub set_username {
        ($username) = @_;
    }

    sub complain_misformed {
        print $errlog_fh "misformed command [$current_goal]\n";
    }

    sub perform {
        my (
            $task,
        ) = @_;

        my ( 
            $cmd,
            @args,
            #$arg1,
            #$arg2,
        ) = split '\s+', $task;

        # now try it
        if (exists($routine{$cmd})) {
            return $routine{$cmd}->(@args); # $arg1, $arg2);
        }
        else {
            print $errlog_fh $task;
            return;
        }
    }
}

sub process_queue {
    my (
        $met_log,
        $set_log,
        $err_log,
    ) = @_;

    # get task queue
    my @queue = prepare_queue($met_log, $set_log);

    say('Creating new log for met goals');
    open $goals_met, ">$met_log"
      or die "$0: can't open $met_log for output: $!\n";
    start_errlog($err_log);

    my $sleep_of_the_just = 5;
    my $error    = 0;
    my $overfull = 0;

    # cache
    set_path();
    set_chkfull();

    TASK:
    while (@queue) { 
        my $task  = shift @queue;
        my $taskp = printable_version($task);
        reset_sleep_time();

        # cache check
        wait_on_cache();

        # stopcopy check
        if (stopfile_exists()) {
            say("Stopfile detected, sleeping...");
            while (stopfile_exists()) {
                sleep 1;
            }
            say("Stopfile removed, resuming...");
        }

        if ($error) {
            require_sleep( failpause() );
        }

        # sleep as needed
        sleep_if_required();

        # heal light wounds
        $error = 0;

        say("Attempting $taskp");

        my $retval = perform($task);

        #next TASK if !defined($retval);

        if(defined($retval) and $retval == 0) {
            say("Successfully performed $taskp");
            print $goals_met $task;

            if ($task =~ m/^send/) {
                sleep $sleep_of_the_just;
            }
        }
        else {
            say("Failed to perform $taskp");
            $error = 1;
            print $err_log $task;
        }
    }

    close($goals_met);
    stop_errlog();
}

sub old_process_queue {
    my (
        $met_log,
        $set_log,
    ) = @_;

    my @queue = prepare_queue($met_log, $set_log);

    say('Creating new log for met goals');
    open my $met_log_fh, ">$met_log"
      or croak("$0: can't open $met_log for $output: $!");

    TASK:
    while (@queue) {
        my $task  = shift @queue;
        my $taskp = printable_version($task);

        say("Attempting $taskp");
        my $retval = perform($task);

        # undefined $retval means we can't perform the task
        next TASK if !defined($retval);

        # 0 is Unix for success 
        if($retval == 0) {
            say("Successfully performed $taskp");
            print $met_log_fh $task;
        }

        # check for sleep requirements
        sleep_if_need_be();
    }
} 

sub prepare_queue {
    my (
        $met_log,
        $set_log,
    ) = @_;

    my @queue = ();

    say('Checking for log of met goals');
    my $met_ref = scan_met_log($met_log);

    # move set log to backup based on time
    my $set_log_bak = join '_', $set_log, time;
    say("Moving $set_log to $set_log_bak");
    move($set_log, $set_log_bak);

    # create new set log containing only unmet goals
    say('Preparing list of current goals');
    open my $set_log_fh, ">$set_log" 
      or croak("$0: can't open logfile $set_log for output: $!");
    open my $set_log_bak_fh, "<$set_log_bak" 
      or croak("$0: can't open logfile $set_log_bak for output: $!");

    while (my $goal = <$set_log_bak_fh>) {
        if (!$met_ref->{$goal}) {
            print $set_log_fh $goal;

            if ($goal =~ m/\S/) {
                push @queue, $goal;
            }
        }
    }
    close $set_log_fh;
    close $set_log_bak_fh;

    # clear stale files
    say("Removing $set_log_bak");
    unlink $set_log_bak
      or croak("$0: can't delete temporary file $set_log_bak: $!");
    say("Clobbering $met_log");
    open my $met_log_fh, ">$met_log"
      or croak("$0: can't open $met_log for clobbering time: $!");
    close $met_log_fh;

    return @queue;
}

sub scan_met_log {
    my (
        $met_log,
    ) = @_;

    my    %met;
    undef %met;

    # if there is a nonempty met log, read it and mark each item as done
    if ( -e $met_log && -s $met_log) {
        say( 'Nonempty log found, scanning.' );
        open my $met_fh, "<$met_log"
          or die "$0: can't open $met_log for input: $!\n";
        while (my $goal = <$met_fh>) {
            $met{$goal} = 1;
        }
    }
    return \%met;
}

sub say {
    print @_, "\n";
}

main(@ARGV);

################################################################
# TESTS FOLLOW

sub runtests {
    ############################################################
    # CAN YOU CACHE A CHECK?
    #
    #
    # fake cache fills
    my @cache_fills = (
        66 => 0,  67 => 0,  72 => 1,  73 => 1, 62 => 1, 66 => 1, 
        60 => 0,  73 => 1,  61 => 1,  55 => 0, 72 => 1, 33 => 0,
    );
    while(@cache_fills) {
        my $fill   = shift @cache_fills;
        my $result = shift @cache_fills;
        is(cache_overfull_helper($fill), $result, "overfull $fill");
    }
    
    # first check
    is(cache_needs_checking(), 1,                 'cache_needs_checking()'  );

    # can we find chkfull?
    is(-e set_chkfull(), 1,                       'set chkfull script'      );
    is(-e get_chkfull(), 1,                       'get chkfull script'      );
    is(get_chkfull(), get_path() . '/chkfull.sh', 'path + script'           );

    # run chkfull
    like(update_cache_fill(), qr/^\d+$/,          'actual check on hpc'     );

    # second check
    is(cache_needs_checking(), 0,                 'cache_needs_checking()'  );

    ############################################################
    # STOPFILE AND FRIENDS
    #
    ok(set_path(),                                'set path'                );
    ok(get_path(),                                'get path'                );
    like(set_stopfile(),   qr/stopcopy$/,         'set stopfile'            );
    like(get_stopfile(),   qr/stopcopy$/,         'get stopfile'            );

    # save stopfile state
    my $prior;
    ok(defined($prior = stopfile_exists()),       'saving stopfile state'   );

    # A few rounds of creating and destroying the stopfile
    is(destroy_stopfile(), 1,                     'destroy stopfile'        );
    is(stopfile_exists(),  0,                     'stopfile really gone'    );
    is(create_stopfile(),  1,                     'create stopfile'         );
    is(stopfile_exists(),  1,                     'stopfile really created' );
    is(destroy_stopfile(), 1,                     'destroy stopfile'        );
    is(stopfile_exists(),  0,                     'stopfile really gone'    );
    is(destroy_stopfile(), 1,                     'destroy stopfile'        );
    is(stopfile_exists(),  0,                     'stopfile really gone'    );
    is(create_stopfile(),  1,                     'create stopfile'         );
    is(stopfile_exists(),  1,                     'stopfile really created' );

    # now restore the stopfile state
    if($prior) {
        ok(create_stopfile(),                     'restoring stopfile state');
    }
    else {
        ok(destroy_stopfile(),                    'restoring stopfile state');
    }

    ############################################################
    # SSH STUFF
    #
    #is(set_username('benji'),  'benji',            'set username to benji'
    #)
    #ok(set_username('benji'),                     'set username to benji'   );
    #is(get_username(),     'benji',               'really set to benji'     );
    #diag('-- Username is ', get_username()                                  );

    #ok(get_username(),                            'got username'            );
    #diag('-- Username is ', get_username()                                  );
    #ok(set_username('benji'),                     'set username to benji'   );
    #is(get_username(),     'benji',               'really set to benji'     );
}
