#!perl

use strict;
use warnings;

use Test::More $^O eq 'MSWin32' ? (
    skip_all => 'no fork() on Win32')
: (
    tests => 200
);
use Test::Requires qw(CGI);
use Test::Fatal;
use CGI::Compile;
use POSIX ':sys_wait_h';
use Capture::Tiny qw/capture_stdout capture_stderr/;

my %children;

$SIG{CHLD} = sub {
    while ((my $child = waitpid(-1, WNOHANG)) > 0) {
        delete $children{$child};

        if ($? >> 8 == 0) {
            pass("no race condition in child $child");
        }
        else {
            fail("race condition detected in child $child");
        }
    }
};

for (1..40) {
    my $errors = capture_stderr {
        # Use four simultaneous processes.
        for (1..4) {
            my $child = fork();

            if (!defined($child)) {
                die "fork failed: $!";
            }

            if ($child == 0) {
                my $sub;
                my $compile_exception = exception { $sub = CGI::Compile->compile("t/hello.cgi") };

                $ENV{REQUEST_METHOD} = 'GET';
                $ENV{QUERY_STRING} = 'name=foo';

                my $matches;

                if (ref $sub) {
                    $matches = capture_stdout { $sub->() } =~ /^Hello foo/m;
                }

                if (!defined($compile_exception) && $matches) {
                    exit(0);
                }
                else {
                    print STDERR $compile_exception;
                    exit(1);
                }
            }
            else {
                $children{$child} = 1;
            }
        }

        # Wait for SIGCHLD reaper.
        select(undef, undef, undef, 0.1) while keys %children;
    };

    is $errors, '', 'no errors during runtime or global destruction';
}

done_testing;
