package Zonemaster::Test::Nameserver v1.0.1;

use strict;
use warnings;

use 5.014002;

use Zonemaster;
use Zonemaster::Util;
use Zonemaster::Test::Address;
use Zonemaster::Constants qw[:ip];

use List::MoreUtils qw[uniq none];
use Text::Capitalize qw[scramble_case];

###
### Entry Points
###

sub all {
    my ( $class, $zone ) = @_;
    my @results;

    if ( Zonemaster->config->should_run( 'nameserver01' ) ) {
        push @results, $class->nameserver01( $zone );
    }
    if ( Zonemaster->config->should_run( 'nameserver02' ) ) {
        push @results, $class->nameserver02( $zone );
    }
    if ( Zonemaster->config->should_run( 'nameserver03' ) ) {
        push @results, $class->nameserver03( $zone );
    }
    if ( Zonemaster->config->should_run( 'nameserver04' ) ) {
        push @results, $class->nameserver04( $zone );
    }
    if ( Zonemaster->config->should_run( 'nameserver05' ) ) {
        push @results, $class->nameserver05( $zone );
    }
    if ( Zonemaster->config->should_run( 'nameserver06' ) ) {
        push @results, $class->nameserver06( $zone );
    }
    if ( Zonemaster->config->should_run( 'nameserver07' ) ) {
        push @results, $class->nameserver07( $zone );
    }
    if ( Zonemaster->config->should_run( 'nameserver08' ) ) {
        push @results, $class->nameserver08( $zone );
    }
    if ( Zonemaster->config->should_run( 'nameserver09' ) ) {
        push @results, $class->nameserver09( $zone );
    }

    return @results;
} ## end sub all

###
### Metadata Exposure
###

sub metadata {
    my ( $class ) = @_;

    return {
        nameserver01 => [
            qw(
              IS_A_RECURSOR
              NO_RECURSOR
              )
        ],
        nameserver02 => [
            qw(
              EDNS0_BAD_QUERY
              EDNS0_BAD_ANSWER
              EDNS0_SUPPORT
              )
        ],
        nameserver03 => [
            qw(
              AXFR_FAILURE
              AXFR_AVAILABLE
              )
        ],
        nameserver04 => [
            qw(
              DIFFERENT_SOURCE_IP
              SAME_SOURCE_IP
              )
        ],
        nameserver05 => [
            qw(
              QUERY_DROPPED
              ANSWER_BAD_RCODE
              IPV4_DISABLED
              IPV6_DISABLED
              )
        ],
        nameserver06 => [
            qw(
              CAN_NOT_BE_RESOLVED
              CAN_BE_RESOLVED
              NO_RESOLUTION
              )
        ],
        nameserver07 => [
            qw(
              UPWARD_REFERRAL_IRRELEVANT
              UPWARD_REFERRAL
              NO_UPWARD_REFERRAL
              )
        ],
        nameserver08 => [
            qw(
              QNAME_CASE_INSENSITIVE
              QNAME_CASE_SENSITIVE
              )
        ],
        nameserver09 => [
            qw(
              CASE_QUERY_SAME_ANSWER
              CASE_QUERY_DIFFERENT_ANSWER
              CASE_QUERY_SAME_RC
              CASE_QUERY_DIFFERENT_RC
              CASE_QUERY_NO_ANSWER
              CASE_QUERIES_RESULTS_OK
              CASE_QUERIES_RESULTS_DIFFER
              )
        ],
    };
} ## end sub metadata

sub translation {
    return {
        'AAAA_WELL_PROCESSED' => 'The following nameservers answer AAAA queries without problems : {names}.',
        'EDNS0_BAD_QUERY'     => 'Nameserver {ns}/{address} does not support EDNS0 (replies with FORMERR).',
        'DIFFERENT_SOURCE_IP' =>
          'Nameserver {ns}/{address} replies on a SOA query with a different source address ({source}).',
        'SAME_SOURCE_IP'      => 'All nameservers reply with same IP used to query them.',
        'AXFR_AVAILABLE'      => 'Nameserver {ns}/{address} allow zone transfer using AXFR.',
        'AXFR_FAILURE'        => 'AXFR not available on nameserver {ns}/{address}.',
        'QUERY_DROPPED'       => 'Nameserver {ns}/{address} dropped AAAA query.',
        'IS_A_RECURSOR'       => 'Nameserver {ns}/{address} is a recursor.',
        'NO_RECURSOR'         => 'None of the following nameservers is a recursor : {names}.',
        'ANSWER_BAD_RCODE'    => 'Nameserver {ns}/{address} answered AAAA query with an unexpected rcode ({rcode}).',
        'EDNS0_BAD_ANSWER'    => 'Nameserver {ns}/{address} does not support EDNS0 (OPT not set in reply).',
        'EDNS0_SUPPORT'       => 'The following nameservers support EDNS0 : {names}.',
        'CAN_NOT_BE_RESOLVED' => 'The following nameservers failed to resolve to an IP address : {names}.',
        'CAN_BE_RESOLVED'     => 'All nameservers succeeded to resolve to an IP address.',
        'NO_RESOLUTION'       => 'No nameservers succeeded to resolve to an IP address.',
        'IPV4_DISABLED'       => 'IPv4 is disabled, not sending "{type}" query to {ns}.',
        'IPV6_DISABLED'       => 'IPv6 is disabled, not sending "{type}" query to {ns}.',
        'UPWARD_REFERRAL_IRRELEVANT' => 'Upward referral tests skipped for root zone.',
        'UPWARD_REFERRAL'            => 'Nameserver {ns}/{address} returns an upward referral.',
        'NO_UPWARD_REFERRAL'         => 'None of the following nameservers returns an upward referral : {names}.',
        'QNAME_CASE_SENSITIVE'       => 'Nameserver {ns}/{address} preserves original case of queried names.',
        'QNAME_CASE_INSENSITIVE'     => 'Nameserver {ns}/{address} does not preserve original case of queried names.',
        'CASE_QUERY_SAME_ANSWER'      => 'When asked for {type} records on "{query1}" and "{query2}", nameserver {ns}/{address} returns same answers.',
        'CASE_QUERY_DIFFERENT_ANSWER' => 'When asked for {type} records on "{query1}" and "{query2}", nameserver {ns}/{address} returns different answers.',
        'CASE_QUERY_SAME_RC'          => 'When asked for {type} records on "{query1}" and "{query2}", nameserver {ns}/{address} returns same RCODE "{rcode}".',
        'CASE_QUERY_DIFFERENT_RC'     => 'When asked for {type} records on "{query1}" and "{query2}", nameserver {ns}/{address} returns different RCODE ("{rcode1}" vs "{rcode2}").',
        'CASE_QUERY_NO_ANSWER'        => 'When asked for {type} records on "{query}", nameserver {ns}/{address} returns nothing.',
        'CASE_QUERIES_RESULTS_OK'     => 'When asked for {type} records on "{query}" with different cases, all servers reply consistently.',
        'CASE_QUERIES_RESULTS_DIFFER' => 'When asked for {type} records on "{query}" with different cases, all servers do not reply consistently.',
    };
} ## end sub translation

sub version {
    return "$Zonemaster::Test::Nameserver::VERSION";
}

sub nameserver01 {
    my ( $class, $zone ) = @_;
    my $nonexistent_name = q{xx--domain-cannot-exist.xx--illegal-syntax-tld};
    my @results;
    my %ips;
    my %nsnames;

    foreach
      my $local_ns ( @{ Zonemaster::TestMethods->method4( $zone ) }, @{ Zonemaster::TestMethods->method5( $zone ) } )
    {

        next if ( not Zonemaster->config->ipv6_ok and $local_ns->address->version == $IP_VERSION_6 );

        next if ( not Zonemaster->config->ipv4_ok and $local_ns->address->version == $IP_VERSION_4 );

        next if $ips{ $local_ns->address->short };

        my $p = $local_ns->query( $nonexistent_name, q{SOA}, { recurse => 1 } );

        if ( $p ) {
            if ( $p->rcode eq q{NXDOMAIN} ) {
                push @results,
                  info(
                    IS_A_RECURSOR => {
                        ns      => $local_ns->name,
                        address => $local_ns->address->short,
                        dname   => $nonexistent_name,
                    }
                  );
            }
            $nsnames{ $local_ns->name }++;
            $ips{ $local_ns->address->short }++;
        }

    } ## end foreach my $local_ns ( @{ Zonemaster::TestMethods...})

    if ( scalar keys %nsnames and not scalar @results ) {
        push @results,
          info(
            NO_RECURSOR => {
                names => join( q{,}, sort keys %nsnames ),
            }
          );
    }

    return @results;
} ## end sub nameserver01

sub nameserver02 {
    my ( $class, $zone ) = @_;
    my @results;
    my %nsnames_and_ip;

    foreach
      my $local_ns ( @{ Zonemaster::TestMethods->method4( $zone ) }, @{ Zonemaster::TestMethods->method5( $zone ) } )
    {

        next if ( not Zonemaster->config->ipv6_ok and $local_ns->address->version == $IP_VERSION_6 );

        next if ( not Zonemaster->config->ipv4_ok and $local_ns->address->version == $IP_VERSION_4 );

        next if $nsnames_and_ip{ $local_ns->name->string . q{/} . $local_ns->address->short };

        my $p = $local_ns->query( $zone->name, q{SOA}, { edns_size => 512 } );
        if ( $p ) {
            if ( $p->rcode eq q{FORMERR} ) {
                push @results,
                  info(
                    EDNS0_BAD_QUERY => {
                        ns      => $local_ns->name,
                        address => $local_ns->address->short,
                    }
                  );
            }
            else {
                if ( not $p->has_edns ) {
                    push @results,
                      info(
                        EDNS0_BAD_ANSWER => {
                            ns      => $local_ns->name,
                            address => $local_ns->address->short,
                        }
                      );
                }
            }
        } ## end if ( $p )

        $nsnames_and_ip{ $local_ns->name->string . q{/} . $local_ns->address->short }++;
    } ## end foreach my $local_ns ( @{ Zonemaster::TestMethods...})

    if ( scalar keys %nsnames_and_ip and not scalar @results ) { push @results,
          info(
            EDNS0_SUPPORT => {
                names => join( q{,}, keys %nsnames_and_ip ),
            }
          );
    }

    return @results;
} ## end sub nameserver02

sub nameserver03 {
    my ( $class, $zone ) = @_;
    my @results;
    my %nsnames_and_ip;

    foreach
      my $local_ns ( @{ Zonemaster::TestMethods->method4( $zone ) }, @{ Zonemaster::TestMethods->method5( $zone ) } )
    {

        next if ( not Zonemaster->config->ipv6_ok and $local_ns->address->version == $IP_VERSION_6 );

        next if ( not Zonemaster->config->ipv4_ok and $local_ns->address->version == $IP_VERSION_4 );

        next if $nsnames_and_ip{ $local_ns->name->string . q{/} . $local_ns->address->short };

        my $first_rr;
        eval {
            $local_ns->axfr( $zone->name, sub { ( $first_rr ) = @_; return 0; } );
            1;
        } or do {
            push @results,
              info(
                AXFR_FAILURE => {
                    ns      => $local_ns->name->string,
                    address => $local_ns->address->short,
                }
              );
        };

        if ( $first_rr and $first_rr->type eq q{SOA} ) {
            push @results,
              info(
                AXFR_AVAILABLE => {
                    ns      => $local_ns->name->string,
                    address => $local_ns->address->short,
                }
              );
        }

        $nsnames_and_ip{ $local_ns->name->string . q{/} . $local_ns->address->short }++;
    } ## end foreach my $local_ns ( @{ Zonemaster::TestMethods...})

    return @results;
} ## end sub nameserver03

sub nameserver04 {
    my ( $class, $zone ) = @_;
    my @results;
    my %nsnames_and_ip;

    foreach
      my $local_ns ( @{ Zonemaster::TestMethods->method4( $zone ) }, @{ Zonemaster::TestMethods->method5( $zone ) } )
    {

        next if ( not Zonemaster->config->ipv6_ok and $local_ns->address->version == $IP_VERSION_6 );

        next if ( not Zonemaster->config->ipv4_ok and $local_ns->address->version == $IP_VERSION_4 );

        next if $nsnames_and_ip{ $local_ns->name->string . q{/} . $local_ns->address->short };

        my $p = $local_ns->query( $zone->name, q{SOA} );
        if ( $p ) {
            if ( $p->answerfrom and ( $local_ns->address->short ne Net::IP::XS->new( $p->answerfrom )->short ) ) {
                push @results,
                  info(
                    DIFFERENT_SOURCE_IP => {
                        ns      => $local_ns->name->string,
                        address => $local_ns->address->short,
                        source  => $p->answerfrom,
                    }
                  );
            }
        }
        $nsnames_and_ip{ $local_ns->name->string . q{/} . $local_ns->address->short }++;
    } ## end foreach my $local_ns ( @{ Zonemaster::TestMethods...})

    if ( scalar keys %nsnames_and_ip and not scalar @results ) {
        push @results,
          info(
            SAME_SOURCE_IP => {
                names => join( q{,}, keys %nsnames_and_ip ),
            }
          );
    }

    return @results;
} ## end sub nameserver04

sub nameserver05 {
    my ( $class, $zone ) = @_;
    my @results;
    my %nsnames_and_ip;

    foreach
      my $local_ns ( @{ Zonemaster::TestMethods->method4( $zone ) }, @{ Zonemaster::TestMethods->method5( $zone ) } )
    {

        next if $nsnames_and_ip{ $local_ns->name->string . q{/} . $local_ns->address->short };

        if ( not Zonemaster->config->ipv6_ok and $local_ns->address->version == $IP_VERSION_6 ) {
            push @results,
              info(
                IPV6_DISABLED => {
                    ns   => "$local_ns",
                    type => q{AAAA},
                }
              );
            next;
        }

        if ( not Zonemaster->config->ipv4_ok and $local_ns->address->version == $IP_VERSION_4 ) {
            push @results,
              info(
                IPV4_DISABLED => {
                    ns   => "$local_ns",
                    type => q{AAAA},
                }
              );
            next;
        }

        $nsnames_and_ip{ $local_ns->name->string . q{/} . $local_ns->address->short }++;

        my $p = $local_ns->query( $zone->name, q{AAAA} );

        if ( not $p ) {
            push @results,
              info(
                QUERY_DROPPED => {
                    ns      => $local_ns->name->string,
                    address => $local_ns->address->short,
                }
              );
            next;
        }

        next if not scalar $p->answer and $p->rcode eq q{NOERROR};

        if (   $p->rcode eq q{FORMERR}
            or $p->rcode eq q{SERVFAIL}
            or $p->rcode eq q{NXDOMAIN}
            or $p->rcode eq q{NOTIMPL} )
        {
            push @results,
              info(
                ANSWER_BAD_RCODE => {
                    ns      => $local_ns->name->string,
                    address => $local_ns->address->short,
                    rcode   => $p->rcode,
                }
              );
            next;
        }

    } ## end foreach my $local_ns ( @{ Zonemaster::TestMethods...})

    if ( scalar keys %nsnames_and_ip and none { $_->tag eq q{ANSWER_BAD_RCODE} } @results ) {
        push @results,
          info(
            AAAA_WELL_PROCESSED => {
                names => join( q{,}, keys %nsnames_and_ip ),
            }
          );
    }

    return @results;
} ## end sub nameserver05

sub nameserver06 {
    my ( $class, $zone ) = @_;
    my @results;
    my @all_nsnames = uniq map { lc( $_->string ) } @{ Zonemaster::TestMethods->method2( $zone ) },
      @{ Zonemaster::TestMethods->method3( $zone ) };
    my @all_nsnames_with_ip = uniq map { lc( $_->name->string ) } @{ Zonemaster::TestMethods->method4( $zone ) },
      @{ Zonemaster::TestMethods->method5( $zone ) };
    my @all_nsnames_without_ip;
    my %diff;

    @diff{@all_nsnames} = undef;
    delete @diff{@all_nsnames_with_ip};

    @all_nsnames_without_ip = keys %diff;
    if ( scalar @all_nsnames_without_ip and scalar @all_nsnames_with_ip ) {
        push @results,
          info(
            CAN_NOT_BE_RESOLVED => {
                names => join( q{,}, @all_nsnames_without_ip ),
            }
          );
    }
    elsif ( not scalar @all_nsnames_with_ip ) {
        push @results,
          info(
            NO_RESOLUTION => {
                names => join( q{,}, @all_nsnames_without_ip ),
            }
          );
    }
    else {
        push @results, info( CAN_BE_RESOLVED => {} );
    }

    return @results;
} ## end sub nameserver06

sub nameserver07 {
    my ( $class, $zone ) = @_;
    my @results;
    my %nsnames_and_ip;
    my %nsnames;

    if ( $zone->name eq q{.} ) {
        push @results, info( UPWARD_REFERRAL_IRRELEVANT => {} );
    }
    else {
        foreach my $local_ns ( @{ Zonemaster::TestMethods->method4( $zone ) },
            @{ Zonemaster::TestMethods->method5( $zone ) } )
        {
            next if ( not Zonemaster->config->ipv6_ok and $local_ns->address->version == $IP_VERSION_6 );

            next if ( not Zonemaster->config->ipv4_ok and $local_ns->address->version == $IP_VERSION_4 );

            next if $nsnames_and_ip{ $local_ns->name->string . q{/} . $local_ns->address->short };

            my $p = $local_ns->query( q{.}, q{NS} );
            if ( $p ) {
                my @ns = $p->get_records( q{NS}, q{authority} );

                if ( @ns ) {
                    push @results,
                      info(
                        UPWARD_REFERRAL => {
                            ns      => $local_ns->name->string,
                            address => $local_ns->address->short,
                        }
                      );
                }
            }
            $nsnames{ $local_ns->name }++;
            $nsnames_and_ip{ $local_ns->name->string . q{/} . $local_ns->address->short }++;
        } ## end foreach my $local_ns ( @{ Zonemaster::TestMethods...})

        if ( scalar keys %nsnames_and_ip and not scalar @results ) {
            push @results,
              info(
                NO_UPWARD_REFERRAL => {
                    names => join( q{,}, sort keys %nsnames ),
                }
              );
        }
    } ## end else [ if ( $zone->name eq q{.})]

    return @results;
} ## end sub nameserver07

sub nameserver08 {
    my ( $class, $zone ) = @_;
    my @results;
    my %nsnames_and_ip;
    my $original_name = q{www.}.$zone->name->string;
    my $randomized_uc_name;

    $original_name =~ s/[.]+\z//smgx;

    do {
        $randomized_uc_name = scramble_case $original_name;
    } while ( $randomized_uc_name eq $original_name );

    foreach my $local_ns ( @{ Zonemaster::TestMethods->method4( $zone ) }, @{ Zonemaster::TestMethods->method5( $zone ) } ) {
        next if ( not Zonemaster->config->ipv6_ok and $local_ns->address->version == $IP_VERSION_6 );

        next if ( not Zonemaster->config->ipv4_ok and $local_ns->address->version == $IP_VERSION_4 );

        next if $nsnames_and_ip{ $local_ns->name->string . q{/} . $local_ns->address->short };

        my $p = $local_ns->query( $randomized_uc_name, q{SOA} );

        if ( $p and my ( $qrr ) = $p->question() ) {
            my $qrr_name = $qrr->name();
            $qrr_name =~ s/\.\z//smgx;
            if ( $qrr_name eq $randomized_uc_name ) {
                push @results,
                  info(
                    QNAME_CASE_SENSITIVE => {
                        ns      => $local_ns->name->string,
                        address => $local_ns->address->short,
                        dname   => $randomized_uc_name,
                    }
                  );
            }
            else {
                push @results,
                  info(
                    QNAME_CASE_INSENSITIVE => {
                        ns      => $local_ns->name->string,
                        address => $local_ns->address->short,
                        dname   => $randomized_uc_name,
                    }
                  );
            }
        } ## end if ( $p and my ( $qrr ...))
        $nsnames_and_ip{ $local_ns->name->string . q{/} . $local_ns->address->short }++;
    } ## end foreach my $local_ns ( @{ Zonemaster::TestMethods...})

    return @results;
} ## end sub nameserver08

sub nameserver09 {
    my ( $class, $zone ) = @_;
    my @results;
    my %nsnames_and_ip;
    my $original_name = q{www.}.$zone->name->string;
    my $record_type = q{SOA};
    my $randomized_uc_name1;
    my $randomized_uc_name2;
    my $all_results_match = 1;

    $original_name =~ s/[.]+\z//smgx;

    do {
        $randomized_uc_name1 = scramble_case $original_name;
    } while ( $randomized_uc_name1 eq $original_name );

    do {
        $randomized_uc_name2 = scramble_case $original_name;
    } while ( $randomized_uc_name2 eq $original_name or $randomized_uc_name2 eq $randomized_uc_name1 );

    foreach my $local_ns ( @{ Zonemaster::TestMethods->method4( $zone ) }, @{ Zonemaster::TestMethods->method5( $zone ) } ) {
        next if ( not Zonemaster->config->ipv6_ok and $local_ns->address->version == $IP_VERSION_6 );

        next if ( not Zonemaster->config->ipv4_ok and $local_ns->address->version == $IP_VERSION_4 );

        next if $nsnames_and_ip{ $local_ns->name->string . q{/} . $local_ns->address->short };

        my $p1 = $local_ns->query( $randomized_uc_name1, $record_type );
        my $p2 = $local_ns->query( $randomized_uc_name2, $record_type );

        my $answer1_string;
        my $answer2_string;
        my $json = JSON::XS->new->canonical->pretty;
        if ( $p1 and scalar $p1->answer ) {

            my @answer1 = map { $_->string } sort $p1->answer;
            $answer1_string = $json->encode(\@answer1);

            if ( $p2 and scalar $p2->answer ) {

                my @answer2 = map { $_->string } sort $p2->answer;
                $answer2_string = $json->encode(\@answer2);
            }

            if ( $answer1_string eq $answer2_string ) {
                push @results,
                  info(
                    CASE_QUERY_SAME_ANSWER => {
                        ns      => $local_ns->name,
                        address => $local_ns->address->short,
                        type    => $record_type,
                        query1  => $randomized_uc_name1,
                        query2  => $randomized_uc_name2,
                    }
                  );
            }
            else {
                $all_results_match = 0;
                push @results,
                  info(
                    CASE_QUERY_DIFFERENT_ANSWER => {
                        ns      => $local_ns->name,
                        address => $local_ns->address->short,
                        type    => $record_type,
                        query1  => $randomized_uc_name1,
                        query2  => $randomized_uc_name2,
                    }
                  );
            }

        }
        elsif ( $p1 and $p2 ) {

            if ( $p1->rcode eq $p2->rcode ) {
                push @results,
                  info(
                    CASE_QUERY_SAME_RC => {
                        ns      => $local_ns->name,
                        address => $local_ns->address->short,
                        type    => $record_type,
                        rcode1  => $p1->rcode,
                        rcode2  => $p2->rcode,
                    }
                  );
            }
            else {
                $all_results_match = 0;
                push @results,
                  info(
                    CASE_QUERY_DIFFERENT_RC => {
                        ns      => $local_ns->name,
                        address => $local_ns->address->short,
                        type    => $record_type,
                        rcode1  => $p1->rcode,
                        rcode2  => $p2->rcode,
                    }
                  );
            }

        }
        elsif ( $p1 or $p2 ) {
            $all_results_match = 0;
            push @results,
              info(
                CASE_QUERY_NO_ANSWER => {
                    ns      => $local_ns->name,
                    address => $local_ns->address->short,
                    type    => $record_type,
                    query   => $p1 ? $randomized_uc_name1 : $randomized_uc_name2,
                }
              );
        }

        $nsnames_and_ip{ $local_ns->name->string . q{/} . $local_ns->address->short }++;
    } ## end foreach my $local_ns ( @{ Zonemaster::TestMethods...})

    if ( $all_results_match ) {
        push @results,
          info(
            CASE_QUERIES_RESULTS_OK => {
                type  => $record_type,
                query => $original_name,
            }
          );
    }
    else {
        push @results,
          info(
            CASE_QUERIES_RESULTS_DIFFER => {
                type  => $record_type,
                query => $original_name,
            }
          );
    }

    return @results;
} ## end sub nameserver09

1;

=head1 NAME

Zonemaster::Test::Nameserver - module implementing tests of the properties of a name server

=head1 SYNOPSIS

    my @results = Zonemaster::Test::Nameserver->all($zone);

=head1 METHODS

=over

=item all($zone)

Runs the default set of tests and returns a list of log entries made by the tests

=item translation()

Returns a refernce to a hash with translation data. Used by the builtin translation system.

=item metadata()

Returns a reference to a hash, the keys of which are the names of all test methods in the module, and the corresponding values are references to
lists with all the tags that the method can use in log entries.

=item version()

Returns a version string for the module.

=back

=head1 TESTS

=over

=item nameserver01($zone)

Verify that nameserver is not recursive.

=item nameserver02($zone)

Verify EDNS0 support.

=item nameserver03($zone)

Verify that zone transfer (AXFR) is not available.

=item nameserver04($zone)

Verify that replies from nameserver comes from the expected IP address.

=item nameserver05($zone)

Verify behaviour against AAAA queries.

=item nameserver06($zone)

Verify that each nameserver can be resolved to an IP address.

=item nameserver07($zone)

Check whether authoritative name servers return an upward referral.

=item nameserver08($zone)

Check whether authoritative name servers responses match the case of every letter in QNAME.

=item nameserver09($zone)

Check whether authoritative name servers return same results for equivalent names with different cases in the request.

=back

=cut
