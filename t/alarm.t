use Test::More;
use t::Capture;
use CGI::Compile;

my $sub = CGI::Compile->compile("t/alarm.cgi", undef, no_localize_sig => 1);

my $stdout = do {
    capture_out($sub);
};

is($stdout,'ALARM=ALRM!!!!', 'Alarm caught');

done_testing;
