# $Id: Befunge.pm,v 1.1 2002/04/15 15:43:21 jquelin Exp $
#
# Copyright (c) 2002 Jerome Quelin <jquelin@cpan.org>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

package Inline::Befunge;

=head1 NAME

Inline::Befunge - write Perl subs in Befunge


=head1 SYNOPSIS

    use Inline "Befunge";

    print "9 + 16 = ", add(9, 16), "\n";
    print "9 - 16 = ", substract(9, 16),"\n";

    __END__
    __Befunge__
    BF-sub add
    +q

    BF-sub substract
    -q


=head1 DESCRIPTION

The C<Inline::Befunge> module allows you to put Befunge source code
directly "inline" in a Perl script or module.

This allows you to write cool stuff with all the power of Befunge!


=head1 USING Inline::Befunge

Using C<Inline::Befunge> will seem very similar to using a another
Inline language, thanks to Inline's consistent look and feel.

This section will explain how to use C<Inline::Befunge>. 

For more details on C<Inline>, see C<perldoc Inline>.


=head2 Feeding Inline with your code

The recommended way of using Inline is this:

    use Inline Befunge;

    ...

    __END__
    __Befunge__

      Befunge source code goes here.

But there's much more way to use Inline. You'll find them in C<perldoc
Inline>.


=head2 Defining functions

As a befunge fan, you know that Befunge does not support named
subroutines. So, I introduced a little hack in order for Inline to
work: each subroutine definition should be prepended with C<BF-sub
subname>, and the body of the function should be on the next lines.

Of course, one can write more than one subroutine, as long as you
prepend them with their name.

So, here's a valid example:

    use Inline "Befunge";

    hello();

    __END__
    __Befunge__
    BF-sub hello
    <q_,#! #:<"Hello world!"a

    BF-sub add
    +q

In this example, I defined two functions: C<hello()> and C<add()>, and
you can call them from within perl as if they were valid perl
functions.


=head2 Passing arguments

In order to write useful functions, one should be able to pass
arguments.  This is possible, and one will find the arguments on the
TOSS of the interpreter: this means the stack may not be empty at the
beginning of the run. If you're a purist, then you may ignore this and
call your functions without arguments, and the stack will be empty.

Strings are pushed as 0gnirts. 

B</!\> Remember, Befunge works with a stack: the first argument will
be the first pushed, ie, the deeper in the stack.

For example, when calling a inlined Befunge function like this: C<foo(
'bar', 7, 'baz' );>, then the stack will be (bottom->top): C<(0 114 97
98 7 0 122 97 98)>.


=head2 Return values

Furthermore, one can return some values from the befunge
subroutines... how exciting!

To do so, the Befunge semantics have been a little adapted:

=over 4

=item o

when an Instruction Pointer reaches a C<q> instruction, one cell will
be popped from its stack and will be returned. This works like a
scalar return.

=item o

when an Instruction Pointer reaches a C<@> instruction, it will be
killed (just as in traditional Befunge). But when the B<last> IP
reaches a C<@>, then the sub is exited and will return the whole stack
of the IP that just died. This works like a list return.

B</!\> Be careful, that you will return a list of integer values. You
are to decide what to do with those values (especially, you are to
convert back to characters with the C<chr> perl builtin function and
join the chars if you're waiting for a string!).

=back

=cut

# A little anal retention ;-)
use strict;
use warnings;

# Modules we relied upon.
use Carp;       # This module can't explode :o)
require Inline; # use Inline forbidden.
use Language::Befunge;

# Inheritance.
use base qw! Inline !;

# Public variables of the module.
our $VERSION   = '0.01';


=head1 PUBLIC METHODS

=head2 register(  )

Register as an Inline Language Support Module.

=cut
sub register {
    return 
      { language => 'Befunge',
        aliases  => [ 'befunge', 'BEFUNGE', 'bf', 'BF' ],
        type     => 'interpreted',
        suffix   => 'bf',
      };
}

=head2 validate(  )

Check the params for the Befunge interpreter. Currently no options are
supported.

=cut
sub validate {
    my $self = shift;
    while(@_ >= 2) {
        my ($key, $value) = (shift, shift);
        croak "Unsupported option found: '$key'.";
    }
}


=head2 build(  )

Register the Befunge as a valid Inline extension.

=cut
sub build {
    my $self = shift;
    # The magic incantations to register.
    my $path = $self->{API}{install_lib}."/auto/".$self->{API}{modpname};
    $self->mkpath($path) unless -d $path;
}


=head2 load(  )

This function actually fetches the Befunge code. It first splits it to
find the functions.

=cut
sub load {
    # Fetch object and package.
    my $self = shift;
    my $pkg  = $self->{API}{pkg} || 'main';

    # Fetch code and create the interpreter.
    my $code = $self->{API}{code};
    my $bef  =  new Language::Befunge;

    # Parse the code.
    # Each subroutine should be:
    # BF-sub subname1
    # < @ ,,,,"foo"a
    # BF-sub subname2
    # etc.
    my @elems = split /BF-sub (.+)\n/, $code;
    shift @elems; # get rid of the garbage prepended.

    while ( @elems ) {
        my $subname = shift @elems;
        my $subcode = shift @elems;

        no strict 'refs';
        *{"${pkg}::$subname"} = 
          sub {
              # Cosmetics.
              $bef->debug( "\n-= SUBROUTINE $subname =-\n" );
              #$bef->DEBUG(1);
              # Store code.
              $bef->store_code( $subcode );
              $bef->file( "Inline-$subname" );

              # Create the first Instruction Pointer.
              my $ip = new Language::Befunge::IP;
              foreach my $arg ( @_ ) {
                  # Fill the stack with arguments.
                  $ip->spush
                    ( ($arg =~ /^-?\d+$/) ?
                        $arg                                    # A number.
                      : reverse map {ord} split //, $arg.chr(0) # A string.
                    );
              }
              $bef->ips( [ $ip ] );
              $bef->kcounter(-1);
              $bef->retval(0);

              # Loop as long as there are IPs.
              $bef->next_tick while scalar @{ $bef->ips };

              # Return the exit code and the TOSS.
              return $bef->lastip->end eq '@' ?
                  @{ $bef->lastip->toss }  # return the TOSS.
                : $bef->retval;             # return exit code.
          };

    }
}


=head2 info(  )

Return a small report about the Foo code.

=cut
sub info {
    my $self = shift;
    my $text = <<'END';
This is a Concurrent Befunge-98 interpreter. In fact, it's just a wrap
around the Language::Befunge module.

perldoc Language::Befunge for more information.
END
    return $text;
}


1;
__END__

=head1 AUTHOR

Jerome Quelin, E<lt>jquelin@cpan.orgE<gt>


=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 SEE ALSO

=over 4

=item L<perl>

=item L<Inline>

=item L<Language::Befunge>

=item L<http://www.catseye.mb.ca/esoteric/befunge/>

=item L<http://dufflebunk.iwarp.com/JSFunge/spec98.html>

=back

=cut

