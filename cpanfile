requires 'File::pushd';
requires 'perl', '5.008001';

on test => sub {
    requires 'Test::More';
    requires 'Test::NoWarnings';
    requires 'Test::Requires';
    requires 'Capture::Tiny';
    requires 'Try::Tiny';
    requires 'CGI';
    requires 'Switch';
};
