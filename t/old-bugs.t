use Test::More;

use Zonemaster;
use Zonemaster::Nameserver;
use Zonemaster::Test::Delegation;

use List::MoreUtils qw[any none];

my $datafile = q{t/old-bugs.data};
if ( not $ENV{ZONEMASTER_RECORD} ) {
    die q{Stored data file missing} if not -r $datafile;
    Zonemaster::Nameserver->restore( $datafile );
    Zonemaster->config->no_network( 1 );
}

my @res = Zonemaster->test_method( q{basic}, q{basic01}, Zonemaster->zone( q{001.tf} ) );
is( $res[2]->tag, q{PARENT_REPLIES}, 'Running single tests in Basic works.' );

@res = Zonemaster->test_method( 'Syntax', 'syntax03', 'XN--MGBERP4A5D4AR' );
is( $res[2]->tag, q{NO_DOUBLE_DASH}, 'No complaint for XN--MGBERP4A5D4AR' );

my $zft_zone = Zonemaster->zone( 'zft.rd.nic.fr' );
is( scalar( @{ $zft_zone->ns } ), 2, 'Two nameservers for zft.rd.nic.fr.' );

my $root = Zonemaster->zone( '.' );
my @msg = Zonemaster->test_method( 'Delegation', 'delegation03', $root );

ok( any { $_->tag eq 'REFERRAL_SIZE_OK' } @msg );
ok( none { $_->tag eq 'MODULE_ERROR' } @msg );

my $nf = Zonemaster->zone( 'nic.fr' );
is( scalar( @{ $nf->glue_names } ), 6, 'All glue names' );
is( scalar( @{ $nf->glue } ),       11, 'All glue objects' );
is( scalar( @{ $nf->ns_names } ),   6, 'All NS names' );
is( scalar( @{ $nf->ns } ),         11, 'All NS objects' );

my $rootfr = Zonemaster->zone( 'root.fr' );
@res = Zonemaster->test_method( 'DNSSEC', 'dnssec02', $rootfr );
ok( ( none { $_->tag eq 'MODULE_ERROR' } @res ), 'No crash in dnssec02' );

my $gnames = Zonemaster->zone( 'nameserver06-no-resolution.zut-root.rd.nic.fr' )->glue_names;
is( scalar( @$gnames ), 2, 'Two glue names' );

my $tld = Zonemaster->zone( 'abogado' );
@res = Zonemaster->test_method( 'DNSSEC', 'dnssec10', $tld );
ok( ( none { $_->tag eq 'INVALID_NAME_FOUND' } @res ), 'NSEC3 test works for domain with wildcard.' );
ok( ( any { $_->tag eq 'NSEC3_COVERS' } @res ), 'NSEC3 test works for domain with wildcard.' );

my $bobo = Zonemaster->zone( 'bobo.nl' );
@res = Zonemaster->test_method('Address', 'address03', $bobo);
ok( ( none { $_->tag eq 'NO_RESPONSE_PTR_QUERY' } @res ), 'Recursor can deal with CNAMEs when recursing.' );

if ( $ENV{ZONEMASTER_RECORD} ) {
    Zonemaster::Nameserver->save( $datafile );
}

done_testing;
