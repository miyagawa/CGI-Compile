use Test::More;
use CGI::Compile;
use t::Capture;

{
    my $sub = CGI::Compile->compile("t/data.cgi");
    my $out = capture_out($sub);
    like $out, qr/Hello\nWorld/;
}

eval {
    my $sub = CGI::Compile->compile("t/end.cgi");
};

is $@, '';

done_testing;
