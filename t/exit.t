use strict;
use Test::More tests => 2;
use CGI::Compile;
use lib "t";
use Exit;

my $sub = CGI::Compile->compile("t/exit.cgi");
my $out = capture_out($sub);
like $out, qr/Hello/;

pass "Not existing";

Exit::main;

fail "Should exit";

sub capture_out {
    no warnings 'uninitialized';
    my $code = shift;

    my $stdout;
    open my $oldout, ">&STDOUT";
    close STDOUT;
    open STDOUT, ">", \$stdout or die $!;
    select STDOUT; $| = 1;

    $code->();

    open STDOUT, ">&", $oldout;

    return $stdout;
}
