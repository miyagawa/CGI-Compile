use Test::More;
use t::Capture;
use CGI::Compile;

my %orig_sig = %SIG;

# set something special
$SIG{TERM} = $orig_sig{TERM} = sub {TERM};

# perl < 5.8.9 won't set a %SIG entry to undef, it sets it to ''
%orig_sig = map { defined $_ ? $_ : '' } %orig_sig
    if $] < 5.008009;

my $sub = CGI::Compile->compile("t/hello.cgi");

is_deeply \%SIG, \%orig_sig, '%SIG preserved during compile';

$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING} = 'name=foo';

my $stdout = capture_out($sub);
like $stdout, qr/Hello foo counter=1/;

is_deeply \%SIG, \%orig_sig, '%SIG preserved during run';

$ENV{QUERY_STRING} = 'exit_status=1';
eval { capture_out($sub) };
is $@, '', 'non-zero exit status';

$ENV{QUERY_STRING} = 'name=bar';
$stdout = capture_out($sub);
like $stdout, qr/Hello bar counter=3/;

done_testing;
