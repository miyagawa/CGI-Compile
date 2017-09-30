use Test::More;
use Test::Requires qw(Switch);
use lib 't';
use Capture;
use CGI::Compile;

my $sub = eval {
    CGI::Compile->compile("t/switch.cgi");
};

if ($@) {
    fail 'CGI with source filter compiles';
    done_testing;
    exit;
}

my $stdout = capture_out($sub);
is $stdout, "switch works\n", 'source filter works in CGI';

done_testing;
