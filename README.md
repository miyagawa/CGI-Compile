# NAME

CGI::Compile - Compile .cgi scripts to a code reference like ModPerl::Registry

# SYNOPSIS

    use CGI::Compile;
    my $sub = CGI::Compile->compile("/path/to/script.cgi");

# DESCRIPTION

CGI::Compile is a utility to compile CGI scripts into a code
reference that can run many times on its own namespace, as long as the
script is ready to run on a persistent environment.

**NOTE:** for best results, load [CGI::Compile](https://metacpan.org/pod/CGI%3A%3ACompile) before any modules used by your
CGIs.

# RUN ON PSGI

Combined with [CGI::Emulate::PSGI](https://metacpan.org/pod/CGI%3A%3AEmulate%3A%3APSGI), your CGI script can be turned
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

You can also set `return_exit_val`, see ["RETURN CODE"](#return-code) for details.

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

# SCRIPT ENVIRONMENT

## ARGUMENTS

Things like the query string and form data should generally be in the
appropriate environment variables that things like [CGI](https://metacpan.org/pod/CGI) expect.

You can also pass arguments to the generated coderef, they will be
locally aliased to `@_` and `@ARGV`.

## `BEGIN` and `END` blocks

`BEGIN` blocks are called once when the script is compiled.
`END` blocks are called when the Perl interpreter is unloaded.

This may cause surprising effects. Suppose, for instance, a script that runs
in a forking web server and is loaded in the parent process. `END`
blocks will be called once for each worker process and another time
for the parent process while `BEGIN` blocks are called only by the
parent process.

## `%SIG`

The `%SIG` hash is preserved meaning the script can change signal
handlers at will. The next invocation gets a pristine `%SIG` again.

## `exit` and exceptions

Calls to `exit` are intercepted and converted into exceptions. When
the script calls `exit 19` and exception is thrown and `$@` contains
a reference pointing to the array

    ["EXIT\n", 19]

Naturally, ["$^S" in perlvar](https://metacpan.org/pod/perlvar#S) (exceptions being caught) is always `true`
during script runtime.

If you really want to exit the process call `CORE::exit` or set
`$CGI::Compile::USE_REAL_EXIT` to true before calling exit:

    $CGI::Compile::USE_REAL_EXIT = 1;
    exit 19;

Other exceptions are propagated out of the generated coderef. The coderef's
caller is responsible to catch them or the process will exit.

## Return Code

The generated coderef's exit value is either the parameter that was
passed to `exit` or the value of the last statement of the script. The
return code is converted into an integer.

On a `0` exit, the coderef will return `0`.

On an explicit non-zero exit, by default an exception will be thrown of
the form:

    exited nonzero: <n>

where `n` is the exit value.

This only happens for an actual call to ["exit" in perfunc](https://metacpan.org/pod/perfunc#exit), not if the last
statement value is non-zero, which will just be returned from the
coderef.

If you would prefer that explicit non-zero exit values are returned,
rather than thrown, pass:

    return_exit_val => 1

in your call to ["new"](#new).

Alternately, you can change this behavior globally by setting:

    $CGI::Compile::RETURN_EXIT_VAL = 1;

## Current Working Directory

If `CGI::Compile->compile` was passed a script file, the script's
directory becomes the current working directory during the runtime of
the script.

NOTE: to be able to switch back to the original directory, the compiled
coderef must establish the current working directory. This operation may
cause an additional flush operation on file handles.

## `STDIN` and `STDOUT`

These file handles are not touched by `CGI::Compile`.

## The `DATA` file handle

If the script reads from the `DATA` file handle, it reads the `__DATA__`
section provided by the script just as a normal script would do. Note,
however, that the file handle is a memory handle. So, `fileno DATA` will
return `-1`.

## CGI.pm integration

If the subroutine `CGI::initialize_globals` is defined at script runtime,
it is called first thing by the compiled coderef.

# PROTECTED METHODS

These methods define some of the internal functionality of
[CGI::Compile](https://metacpan.org/pod/CGI%3A%3ACompile) and may be overloaded if you need to subclass this
module.

## \_read\_source

Reads the source of a CGI script.

Parameters:

- `$file_path`

    Path to the file the contents of which is to be read.

Returns:

- `$source`

    The contents of the file as a scalar string.

## \_build\_subname

Creates a package name and coderef name into which the CGI coderef will be
compiled into. The package name will be prepended with
`$self-`{namespace\_root}>.

Parameters:

- `$file_path`

    The path to the CGI script file, the package name is generated based on
    this path.

Returns:

- `$package`

    The generated package name.

- `$subname`

    The generated coderef name, based on the file name (without directory) of the
    CGI file path.

## \_eval

Takes the generated perl code, which is the contents of the CGI script
and some other things we add to make everything work smoother, and
returns the evaluated coderef.

Currently this is done by writing out the code to a temp file and
reading it in with ["do" in perlfunc](https://metacpan.org/pod/perlfunc#do) so that there are no issues with
lexical context or source filters.

Parameters:

- `$code`

    The generated code that will make the coderef for the CGI.

Returns:

- `$coderef`

    The coderef that is the resulting of evaluating the generated perl code.

# AUTHOR

Tatsuhiko Miyagawa <miyagawa@bulknews.net>

# CONTRIBUTORS

Rafael Kitover <rkitover@gmail.com>

Hans Dieter Pearcey <hdp@cpan.org>

kocoureasy <igor.bujna@post.cz>

Torsten Förtsch <torsten.foertsch@gmx.net>

Jörn Reder <jreder@dimedis.de>

Pavel Mateja <pavel@verotel.cz>

lestrrat &lt;lestrrat+github@gmail.com>

# COPYRIGHT & LICENSE

Copyright (c) 2023 Tatsuhiko Miyagawa <miyagawa@bulknews.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[ModPerl::RegistryCooker](https://metacpan.org/pod/ModPerl%3A%3ARegistryCooker) [CGI::Emulate::PSGI](https://metacpan.org/pod/CGI%3A%3AEmulate%3A%3APSGI)
