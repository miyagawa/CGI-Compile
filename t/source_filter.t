use Test::More;
use Test::Requires qw(Switch);
use t::Capture;
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
like $stdout, qr/^switch works/, 'source filter works in CGI';

done_testing;
