use strict;
use Test::More;
use File::Spec ();
eval q{ use Test::Perl::Critic };
plan skip_all => "Test::Perl::Critic is not installed." if $@;
my $rcfile = File::Spec->catfile('xt', 'perlcriticrc');
Test::Perl::Critic->import(-profile => $rcfile);
all_critic_ok("lib");
