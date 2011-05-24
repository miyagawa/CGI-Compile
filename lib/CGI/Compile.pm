package CGI::Compile;

use strict;
use 5.008_001;
our $VERSION = '0.15';

use Cwd;
use File::Basename;
use File::Spec::Functions;
use File::pushd;

sub new {
    my ($class, %opts) = @_;

    $opts{namespace_root} ||= 'CGI::Compile::ROOT';

    bless \%opts, $class;
}

our $USE_REAL_EXIT;
BEGIN {
    $USE_REAL_EXIT = 1;

    my $orig = *CORE::GLOBAL::exit{CODE};

    my $proto = $orig ? prototype $orig : prototype 'CORE::exit';

    $proto = "($proto)" if $proto;

    $orig ||= sub {
        my $exit_code = shift;

        CORE::exit(defined $exit_code ? $exit_code : 0);
    };

    no warnings 'redefine';

    *CORE::GLOBAL::exit = eval qq{
        sub $proto {
            my \$exit_code = shift;

            \$orig->(\$exit_code) if \$USE_REAL_EXIT;

            die [ "EXIT\n", \$exit_code || 0 ]
        };
    };
    die $@ if $@;
}

sub compile {
    my($class, $script, $package) = @_;

    my $self = ref $class ? $class : $class->new;

    my $code = $self->_read_source($script);
    my $path = Cwd::abs_path($script);
    my $dir  = File::Basename::dirname($path);

    $package ||= $self->_build_package($path);

    my $warnings = $code =~ /^#!.*\s-w\b/ ? 1 : 0;
 
    $code =~ s/^__END__\r?\n.*//ms;
    $code =~ s/^__DATA__\r?\n(.*)//ms;
    my $data = $1;

    # TODO handle nph and command line switches?
    my $eval = join '',
        "package $package;",
        "sub {",
        'local $CGI::Compile::USE_REAL_EXIT = 0;',
        "\nCGI::initialize_globals() if defined &CGI::initialize_globals;",
        "local \$0 = '$path';",
        "my \$_dir = File::pushd::pushd '$dir';",
        'local *DATA;',
        q{open DATA, '<', \$data;},
        'local *SIG = +{ %SIG };',
        'no warnings;',
        ('local $^W = '.$warnings.';'),
        'my $rv = eval {',
        "\n#line 1 $path\n",
        $code,
        "\n};",
        q{
            return $rv unless $@;
            die $@ if $@ and not (
              ref($@) eq 'ARRAY' and
              $@->[0] eq "EXIT\n"
            );
            die "exited nonzero: $@->[1]" if $@->[1] != 0;
            return $rv;
        },
        '};';


    my $sub = do {
        no strict;
        no warnings;

        my %orig_sig  = %SIG;
        local $USE_REAL_EXIT = 0;

        my $code = eval $eval;
        my $exception = $@;

        %SIG = %orig_sig;

        die "Could not compile $script: $exception" if $exception;

        $code;
    };

    return $sub;
}

sub _read_source {
    my($self, $file) = @_;

    open my $fh, "<", $file or die "$file: $!";
    return do { local $/; <$fh> };
}

sub _build_package {
    my($self, $path) = @_;

    my ($volume, $dirs, $file) = File::Spec::Functions::splitpath($path);
    my @dirs = File::Spec::Functions::splitdir($dirs);
    my $package = join '_', grep { defined && length } $volume, @dirs, $file;

    # Escape everything into valid perl identifiers
    $package =~ s/([^A-Za-z0-9_])/sprintf("_%2x", unpack("C", $1))/eg;

    # make sure that the sub-package doesn't start with a digit
    $package =~ s/^(\d)/_$1/;

    $package = $self->{namespace_root} . "::$package";
    return $package;
}

1;

__END__

=encoding utf-8

=for stopwords

=head1 NAME

CGI::Compile - Compile .cgi scripts to a code reference like ModPerl::Registry

=head1 SYNOPSIS

  use CGI::Compile;
  my $sub = CGI::Compile->compile("/path/to/script.cgi");

=head1 DESCRIPTION

CGI::Compile is an utility to compile CGI scripts into a code
reference that can run many times on its own namespace, as long as the
script is ready to run on a persistent environment.

B<NOTE:> for best results, load L<CGI::Compile> before any modules used by your
CGIs.

=head1 RUN ON PSGI

Combined with L<CGI::Emulate::PSGI>, your CGI script can be turned
into a persistent PSGI application like:

  use CGI::Emulate::PSGI;
  use CGI::Compile;

  my $cgi_script = "/path/to/foo.cgi";
  my $sub = CGI::Compile->compile($cgi_script);
  my $app = CGI::Emulate::PSGI->handler($sub);

  # $app is a PSGI application

=head1 CAVEATS

If your CGI script has a subroutine that references the lexical scope
variable outside the subroutine, you'll see warnings such as:

  Variable "$q" is not available at ...
  Variable "$counter" will not stay shared at ...

This is due to the way this module compiles the whole script into a
big C<sub>. To solve this, you have to update your code to pass around
the lexical variables, or replace C<my> with C<our>. See also
L<http://perl.apache.org/docs/1.0/guide/porting.html#The_First_Mystery>
for more details.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 CONTRIBUTORS

Rafael Kitover E<lt>rkitover@cpan.orgE<gt>

Hans Dieter Pearcey E<lt>hdp@cpan.orgE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2009 Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<ModPerl::RegistryCooker> L<CGI::Emulate::PSGI>

=cut
