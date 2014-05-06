# NAME

CGI::Compile - Compile .cgi scripts to a code reference like ModPerl::Registry

# SYNOPSIS

    use CGI::Compile;
    my $sub = CGI::Compile->compile("/path/to/script.cgi");

# DESCRIPTION

CGI::Compile is an utility to compile CGI scripts into a code
reference that can run many times on its own namespace, as long as the
script is ready to run on a persistent environment.

**NOTE:** for best results, load [CGI::Compile](https://metacpan.org/pod/CGI::Compile) before any modules used by your
CGIs.

# RUN ON PSGI

Combined with [CGI::Emulate::PSGI](https://metacpan.org/pod/CGI::Emulate::PSGI), your CGI script can be turned
into a persistent PSGI application like:

    use CGI::Emulate::PSGI;
    use CGI::Compile;

    my $cgi_script = "/path/to/foo.cgi";
    my $sub = CGI::Compile->compile($cgi_script);
    my $app = CGI::Emulate::PSGI->handler($sub);

    # $app is a PSGI application

# CAVEATS

If your CGI script has a subroutine that references the lexical scope
variable outside the subroutine, you'll see warnings such as:

    Variable "$q" is not available at ...
    Variable "$counter" will not stay shared at ...

This is due to the way this module compiles the whole script into a
big `sub`. To solve this, you have to update your code to pass around
the lexical variables, or replace `my` with `our`. See also
[http://perl.apache.org/docs/1.0/guide/porting.html#The\_First\_Mystery](http://perl.apache.org/docs/1.0/guide/porting.html#The_First_Mystery)
for more details.

# METHODS

## new

Does not need to be called, you only need to call it if you want to set your
own `namespace_root` for the generated packages into which the CGIs are
compiled into.

Otherwise you can just call ["compile"](#compile) as a class method and the object will
be instantiated with a `namespace_root` of `CGI::Compile::ROOT`.

Example:

    my $compiler = CGI::Compile->new(namespace_root => 'My::CGIs');
    my $cgi      = $compiler->compile('/var/www/cgi-bin/my.cgi');

## compile

Takes either a path to a perl CGI script or a source code and some
other optional parameters and wraps it into a coderef for execution.

Can be called as either a class or instance method, see ["new"](#new) above.

Parameters:

- `$cgi_script`

    Path to perl CGI script file or a scalar reference that contains the
    source code of CGI script, required.

- `$package`

    Optional, package to install the script into, defaults to the path parts of the
    script joined with `_`, and all special characters converted to `_%2x`,
    prepended with `CGI::Compile::ROOT::`.

    E.g.:

        /var/www/cgi-bin/foo.cgi

    becomes:

        CGI::Compile::ROOT::var_www_cgi_2dbin_foo_2ecgi

Returns:

- `$coderef`

    `$cgi_script` or `$$code` compiled to coderef.

# AUTHOR

Tatsuhiko Miyagawa <miyagawa@bulknews.net>

# CONTRIBUTORS

Rafael Kitover <rkitover@cpan.org>

Hans Dieter Pearcey <hdp@cpan.org>

kocoureasy <igor.bujna@post.cz>

Torsten Förtsch <torsten.foertsch@gmx.net>

# COPYRIGHT & LICENSE

Copyright (c) 2009 Tatsuhiko Miyagawa <miyagawa@bulknews.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[ModPerl::RegistryCooker](https://metacpan.org/pod/ModPerl::RegistryCooker) [CGI::Emulate::PSGI](https://metacpan.org/pod/CGI::Emulate::PSGI)
