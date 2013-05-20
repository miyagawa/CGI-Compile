use Test::More;
use CGI::Compile;
use t::Capture;

{
    my $sub = CGI::Compile->compile("t/data.cgi");
    my $out = capture_out($sub);
    like $out, qr/Hello\nWorld/;
}

{
    my $sub = CGI::Compile->compile("t/data_crlf.cgi");
    my $out = capture_out($sub);
    like $out, qr/Hello\r?\nWorld/;
}

eval {
    my $sub = CGI::Compile->compile("t/end.cgi");
};

is $@, '';

eval {
    my $sub = CGI::Compile->compile("t/end_crlf.cgi");
};

is $@, '';

done_testing;
