use CGI;
$COUNTER++;

my $q = CGI->new;
print $q->header, "Hello ", $q->param('name'), " counter=$COUNTER";
