package Zonemaster::Logger v1.0.0;

use 5.14.2;
use Moose;

use Zonemaster::Logger::Entry;
use Zonemaster;
use List::MoreUtils qw[none];
use Scalar::Util qw[blessed];
use JSON::XS;

has 'entries' => (
    is      => 'ro',
    isa     => 'ArrayRef[Zonemaster::Logger::Entry]',
    default => sub { [] }
);
has 'callback' => ( is => 'rw', isa => 'CodeRef', required => 0, clearer => 'clear_callback' );

sub add {
    my ( $self, $tag, $argref ) = @_;

    my $new =
      Zonemaster::Logger::Entry->new( { tag => uc( $tag ), args => $argref } );
    $self->_check_filter( $new );
    push @{ $self->entries }, $new;

    if ( $self->callback and ref( $self->callback ) eq 'CODE' ) {
        eval { $self->callback->( $new ) };
        if ( $@ ) {
            my $err = $@;
            if ( blessed( $err ) and $err->isa( "Zonemaster::Exception" ) ) {
                die $err;
            }
            else {
                $self->clear_callback;
                $self->add( LOGGER_CALLBACK_ERROR => { exception => $err } );
            }
        }
    }

    return $new;
} ## end sub add

sub _check_filter {
    my ( $self, $entry ) = @_;
    my $config = Zonemaster->config->logfilter;

    if ( $config ) {
        if ( $config->{ $entry->module } ) {
            if ( my $rule = $config->{ $entry->module }{ $entry->tag } ) {
                foreach my $key ( keys %{ $rule->{when} } ) {
                    my $cond = $rule->{when}{$key};
                    if ( ref( $cond ) and ref( $cond ) eq 'ARRAY' ) {
                        # No match in list, so overall fail, so return
                        ## no critic (TestingAndDebugging::ProhibitNoWarnings)
                        no warnings 'uninitialized';
                        return if none { $_ eq $entry->args->{$key} } @$cond;
                    }
                    else {
                        # No match, so overall fail, so return
                        ## no critic (TestingAndDebugging::ProhibitNoWarnings)
                        no warnings 'uninitialized';
                        return if $cond ne $entry->args->{$key};
                    }
                }
                # Still here, so all rules matched
                $entry->_set_level( $rule->{set} );
            }
        } ## end if ( $config->{ $entry...})
    } ## end if ( $config )
} ## end sub _check_filter

sub start_time_now {
    Zonemaster::Logger::Entry->start_time_now();
}

sub clear_history {
    my ( $self ) = @_;

    my $r = $self->entries;
    splice @$r, 0, scalar( @$r );

    return;
}

# get the max level from a log, return as a string
sub get_max_level {
    my ( $self ) = @_;

    my %levels = reverse Zonemaster::Logger::Entry->levels();
    my $level = 0;

    foreach ( @{ $self->entries } ) {
	$level = $_->numeric_level if $_->numeric_level > $level;
    }

    return $levels{ $level };
}

sub json {
    my ( $self, $min_level ) = @_;
    my $json    = JSON::XS->new->allow_blessed->convert_blessed->canonical;
    my %numeric = Zonemaster::Logger::Entry->levels();

    my @msg = @{ $self->entries };

    if ( $min_level and defined $numeric{ uc( $min_level ) } ) {
        @msg = grep { $_->numeric_level >= $numeric{ uc( $min_level ) } } @msg;
    }

    my @out;
    foreach my $m ( @msg ) {
        my %r;
        $r{timestamp} = $m->timestamp;
        $r{module}    = $m->module;
        $r{tag}       = $m->tag;
        $r{level}     = $m->level;
        $r{args}      = $m->args if $m->args;

        push @out, \%r;
    }

    return $json->encode( \@out );
} ## end sub json

no Moose;
__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Zonemaster::Logger - class that holds L<Zonemaster::Logger::Entry> objects.

=head1 SYNOPSIS

    my $logger = Zonemaster::Logger->new;
    $logger->add( TAG => {some => 'arguments'});

=head1 ATTRIBUTES

=over

=item entries

A reference to an array holding L<Zonemaster::Logger::Entry> objects.

=item callback($coderef)

If this attribute is set, the given code reference will be called every time a
log entry is added. The referenced code will be called with the newly created
entry as its single argument. The return value of the called code is ignored.

If the called code throws an exception, and the exception is not an object of
class L<Zonemaster::Exception> (or a subclass of it), the exception will be
logged as a system message at default level C<CRITICAL> and the callback
attribute will be cleared.

If an exception that is of (sub)class L<Zonemaster::Exception> is called, the
exception will simply be rethrown until it reaches the code that started the
test run that logged the message.

=back

=head1 METHODS

=over

=item add($tag, $argref)

Adds an entry with the given tag and arguments to the logger object.

=item json([$level])

Returns a JSON-formatted string with all the stored log entries. If an argument
is given and is a known severity level, only messages with at least that level
will be included.

=item get_max_level

Returns the maximum log level from the entire log as the level string.

=back

=head1 CLASS METHOD

=over

=item start_time_now()

Set the logger's start time to the current time.

=item clear_history()

Remove all known log entries.

=back

=cut
