my $alrm; 
eval { 
	$SIG{ALRM} = sub { $alrm="ALRM!!!!"; die; }; 
	eval { 
		alarm 2; 
		while(1){} 
		alarm 0; 
	}; 
}; 
alarm 0; 
print "ALARM=$alrm";
