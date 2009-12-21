use CGI;
$COUNTER++;

$SIG{__DIE__} = sub { 'dummy' };

my $q = CGI->new;

chomp(my $greeting = <DATA>);

print $q->header, $greeting, $q->param('name'), " counter=$COUNTER";

exit;

__DATA__
Hello 
