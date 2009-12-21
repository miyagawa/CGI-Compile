use CGI;
$COUNTER++;

$SIG{__DIE__} = sub { 'dummy' };

my $q = CGI->new;

chomp(my $greeting = <DATA>);

print $q->header, $greeting, $q->param('name'), " counter=$COUNTER";

exit $q->param('exit_status') || 0;

__DATA__
Hello 
