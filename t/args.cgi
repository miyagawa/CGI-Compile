use CGI;

my $q = CGI->new;

print $q->header, "Hello \@_: ", join(',' => @_), ' @ARGV: ', join(',' => @ARGV);
