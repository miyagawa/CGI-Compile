use Test::More;
use CGI::Compile;
use lib "t";
use Exit;

my $sub = CGI::Compile->compile("t/exit.cgi");
$sub->();

pass "Not existing";

done_testing;

Exit::main;

fail "Should exit";
