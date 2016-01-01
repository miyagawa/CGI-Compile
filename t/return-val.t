#!perl

use strict;
use warnings;
use Test::More;
use Test::NoWarnings;
use CGI::Compile;

my $SHEBANG = "#!perl -w\n";

my @TESTS = map $SHEBANG . $_, (
    'undef;', '"bla";', '0.5;',
    'return undef;', 'return "bla";', 'return 0.5;',
    'exit undef;', 'exit "bla";', 'exit 0.5;'
);

foreach my $test (@TESTS) {
    CGI::Compile->compile(\$test)->();
}

done_testing(1);
