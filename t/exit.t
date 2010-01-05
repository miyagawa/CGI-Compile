use Test::More tests => 1;
use CGI::Compile;
use lib "t";
use Exit;

my $sub = CGI::Compile->compile("t/exit.cgi");
$sub->();

pass "Not existing";

Exit::main;

fail "Should exit";
