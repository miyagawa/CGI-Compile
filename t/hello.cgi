use CGI;
$COUNTER++;

BEGIN { $SIG{USR1} = 'IGNORE'; }

$SIG{USR1} = 'IGNORE';

my $q = CGI->new;

chomp(my $greeting = <DATA>);

print $q->header, $greeting, $q->param('name'), " counter=$COUNTER";

exit $q->param('exit_status') || 0;

__DATA__
Hello 
