use Test::More;
use CGI::Compile;

my $sub = CGI::Compile->compile("t/hello.cgi");

$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING} = 'name=foo';

my $stdout = capture_out($sub);
like $stdout, qr/Hello foo counter=1/;

$ENV{QUERY_STRING} = 'name=bar';
$stdout = capture_out($sub);
like $stdout, qr/Hello bar counter=2/;

done_testing;


sub capture_out {
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
