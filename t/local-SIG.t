#!perl

use Test::More tests => 1;
use t::Capture;
use CGI::Compile;

my $sub = CGI::Compile->compile(\<<'EOF');
$SIG{QUIT} = sub{print "QUIT\n"};
kill QUIT => $$;
print "END\n";
EOF

is capture_out($sub), "QUIT\nEND\n", 'caught signal';
