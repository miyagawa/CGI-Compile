#!perl

use Test::More tests => 11;
use CGI::Compile;

is (CGI::Compile->compile(\'0;')->(), 0, 'fall-through exit 0');
is (CGI::Compile->compile(\'exit 0;')->(), 0, 'function exit 0');
is (CGI::Compile->compile(\'1;')->(), 1, 'fall-through exit 1');
is (CGI::Compile->compile(\'exit 1;')->(), 1, 'function exit 1');
is (CGI::Compile->compile(\'"blah";')->(), 0, 'fall-through exit string');
is (CGI::Compile->compile(\'exit "blah";')->(), 0, 'function exit string');
is (CGI::Compile->compile(\'"";')->(), 0, 'fall-through exit empty string');
is (CGI::Compile->compile(\'exit "";')->(), 0, 'function exit empty string');
is (CGI::Compile->compile(\';')->(), 0, 'fall-through exit undef');
is (CGI::Compile->compile(\'exit;')->(), 0, 'function exit implicit undef');
is (CGI::Compile->compile(\'exit undef;')->(), 0, 'function exit explicit undef');
