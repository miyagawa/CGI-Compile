#!perl

use t::Capture;
use CGI::Compile;

use Test::More $^O eq 'MSWin32' ? (
    skip_all => 'not supported on Win32') 
: (
    tests => 1
);

my $sub = CGI::Compile->compile(\<<'EOF');
$SIG{QUIT} = sub{print "QUIT\n"};
kill QUIT => $$;
print "END\n";
EOF

is capture_out($sub), "QUIT\nEND\n", 'caught signal';
