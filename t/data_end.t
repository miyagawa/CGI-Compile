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

{
    my $str =<<EOL;
#!/usr/bin/perl

print "Content-Type: text/plain\015\012\015\012", <DATA>;

__DATA__
Hello
World
EOL

    my $sub = CGI::Compile->compile("t/data.cgi", undef, \$str);
    my $out = capture_out($sub);
    like $out, qr/Hello\nWorld/;
}

done_testing;
