package CGI::Compile;

use strict;
use 5.008_001;
our $VERSION = '0.08';

use Cwd;
use File::Basename;
use File::Spec::Functions;
use File::pushd;

sub new {
    my ($class, %opts) = @_;

    $opts{namespace_root} ||= 'CGI::Compile::ROOT';

    bless \%opts, $class;
}

sub compile {
    my($class, $script, $package) = @_;

    my $self = ref $class ? $class : $class->new;

    my $code = $self->_read_source($script);
    my $path = Cwd::abs_path($script);
    my $dir  = File::Basename::dirname($path);

    $package ||= $self->_build_package($path);
 
    $code =~ s/^__DATA__\n(.*)//ms;
    my $data = $1;

    # TODO handle nph and command line switches?
    my $eval = join '',
        'my $cgi_exited = "EXIT\n";
        BEGIN { *CORE::GLOBAL::exit = sub (;$) {
            die [ $cgi_exited, $_[0] || 0 ];
        } }',
        "package $package;",
        "sub {",
        "CGI::initialize_globals() if defined &CGI::initialize_globals;",
        "local \$0 = '$path';",
        "my \$_dir = File::pushd::pushd '$dir';",
        'local *DATA;',
        q{open DATA, '<', \$data;},
        'local *SIG = +{ %SIG };',
        'my $rv = eval {',
        "\n#line 1 $path\n",
        $code,
        "\n};",
        q{
            return $rv unless $@;
            die $@ if $@ and not (
              ref($@) eq 'ARRAY' and
              $@->[0] eq $cgi_exited
            );
            die "exited nonzero: $@->[1]" if $@->[1] != 0;
            return $rv;
        },
        '};';


    my $sub = do {
        no strict;
        no warnings;

        my $orig_exit = \*CORE::GLOBAL::exit;
        my %orig_sig  = %SIG;

        my $code = eval $eval;

        *CORE::GLOBAL::exit = $orig_exit;
        %SIG = %orig_sig;

        die "Could not compile $script: $@" if $@;
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

=head1 RUN ON PSGI

Combined with L<CGI::Emulate::PSGI>, your CGI script can be turned
into a persistent PSGI application like:

  use CGI::Emulate::PSGI;
  use CGI::Compile;

  my $cgi_script = "/path/to/foo.cgi";
  my $sub = CGI::Compile->compile($cgi_script);
  my $app = CGI::Emulate::PSGI->handler($sub);

  # $app is a PSGI application

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
