# $Id: Befunge.pm,v 1.2 2002/04/16 15:46:48 jquelin Exp $
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
    ;:add; +q

    ;:substract; -q


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

The recommended way of using Inline is the following:

    use Inline Befunge;

    ...

    __END__
    __Befunge__

      Befunge source code goes here.

But there's much more way to use Inline. You'll find them in C<perldoc
Inline>.


=head2 Defining functions

As a befunge fan, you know that Befunge does not support named
subroutines. So, I introduced a little hack (thank goes to Sean
O'Rourke) in order for Inline to work: each subroutine definition
should be prepended with a comment C<;:subname;> (notice the colon
prepended).

You will notice how smart it is, since it's enclosed in comments, and
therefore the overall meaning of the code isn't changed.

You can define you subroutines in any of the four cardinal directions,
and the subroutine velocity will be the velocity defined by the
comment. That is, if you define a subroutine in a vertical comment
from bottom to top, when called, the subroutine will start with a
velocity of (0,-1).

You can add comments after the subname. Thus, C<;:foo - a foo
subroutine;> defines a new subroutine C<foo>.

So, here's a valid example:

    use Inline "Befunge";

    hello();

    __END__
    __Befunge__
    ;:hello - print a msg;<q_,#! #:<"Hello world!"a

        ;
        :
        a             q - ;tcartsbus:; 
        d
        d
        ;
        +  ;not a valid func def;
        q


In this example, I defined three functions: C<hello()>, C<add()> and
C<substract>, and you can call them from within perl as if they were
valid perl functions. The fourth comment C<;not a valid func def;>
isn't a valid function definition since it lacks a colon C<:> just
after the C<;>.


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
our $VERSION   = '0.02';


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
    #$bef->DEBUG(1);
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
    my $bef  = $self->{ILSM}{bef} =  new Language::Befunge;
    $bef->store_code( $code );

    # Parse the code.
    # Each subroutine should be:
    # ;:subname1; < @ ,,,,"foo"a
    # ;:subname2;
    # etc.
    my $funcs = $bef->torus->labels_lookup;
    $self->{ILSM}{funcs} = join " ", sort keys %$funcs;
    
    foreach my $subname ( keys %$funcs ) {
        no strict 'refs';
        *{"${pkg}::$subname"} = 
          sub {
              # Cosmetics.
              $bef->debug( "\n-= SUBROUTINE $subname =-\n" );
              $bef->file( "Inline-$subname" );

              # Create the first Instruction Pointer.
              my $ip = new Language::Befunge::IP;

              # Move the IP at the beginning of the function.
              $ip->curx( $funcs->{$subname}[0] );
              $ip->cury( $funcs->{$subname}[1] );
              $ip->dx( $funcs->{$subname}[2] );
              $ip->dy( $funcs->{$subname}[3] );

              # Fill the stack with arguments.
              foreach my $arg ( @_ ) {
                  $ip->spush
                    ( ($arg =~ /^-?\d+$/) ?
                        $arg                                    # A number.
                      : reverse map {ord} split //, $arg.chr(0) # A string.
                    );
              }

              # Initialize the interpreter.
              $bef->ips( [ $ip ] );
              $bef->kcounter(-1);
              $bef->retval(0);

              # Loop as long as there are IPs.
              $bef->next_tick while scalar @{ $bef->ips };

              # Return the exit code and the TOSS.
              return $bef->lastip->end eq '@' ?
                  @{ $bef->lastip->toss }  # return the TOSS.
                : $bef->retval;            # return exit code.
          };

    }
}


=head2 info(  )

Return a small report about the Befunge code.

=cut
sub info {
    my $self = shift;
    my $text = <<'END';
The following functions have been defined via Inline::Befunge:
$self->{ILSM}{funcs}
END
    return $text;
}


1;
__END__

=head1 AUTHOR

Jerome Quelin, E<lt>jquelin@cpan.orgE<gt>


=head1 ACKNOWLEDGEMENTS

I would like to thank:

=over 4

=item o

Brian Ingerson, for writing the incredibly cool C<Inline> module, and
giving the world's programmers enough rope to hang themselves many
times over.

=item o

Chris Pressey, creator of Befunge, who gave a whole new dimension to
both coding and obfuscating.

=item o

Sean O'Rourke E<lt>seano@alumni.rice.eduE<gt> for his incredible cool
idea on defining labels in Befunge code.

=back


=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 SEE ALSO

=over 4

=item L<perl>

=item L<Inline>

=item L<Language::Befunge>

=back

=cut

