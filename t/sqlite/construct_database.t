use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Exception;
use Test::Fixture::DBI;
use Test::Fixture::DBI::Connector::SQLite;

my $connector = 'Test::Fixture::DBI::Connector::SQLite';

sub test_database {
    my ( $dbh, $type, $expected_types ) = @_;

    my $expected_type_map = +{
        map { ( $_ => +{ name => $_ }, ) }
        sort { $a cmp $b } @$expected_types
    };
    my $got_type_map = $dbh->selectall_hashref(
'SELECT name FROM sqlite_master WHERE type = ? AND sql IS NOT NULL ORDER BY name ASC',
        'name', +{ Slice => +{} }, $type,
    );

    is_deeply( $got_type_map, $expected_type_map,
        sprintf( 'exists %s (%s)', $type, join( ', ', @$expected_types ) ) );

}

subtest 'default' => sub {
    my $dbh = $connector->dbh;
    my $database;

    lives_ok(
        sub {
            $database = construct_database(
                dbh      => $dbh,
                database => 't/sqlite/schema.yaml'
            );
        },
        'construct_database() will be success',
    );

    test_database( $dbh, 'table',
        [qw/friend friend_counter people people_counter/] );

    test_database(
        $dbh, 'index',
        [
            qw/idx_people_on_id_and_created_on idx_people_on_id_and_updated_on idx_people_on_nickname/
        ]
    );

    done_testing;
};

subtest 'with schema' => sub {
    my $dbh = $connector->dbh;
    my $database;

    lives_ok(
        sub {
            $database = construct_database(
                dbh      => $dbh,
                database => 't/sqlite/schema.yaml',
                schema   => [qw/friend friend_counter/],
            );
        },
        'construct_database() will be success',
    );

    test_database( $dbh, 'table', [qw/friend friend_counter/] );
    test_database( $dbh, 'index', [] );

    done_testing;
};

done_testing;

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# coding: utf-8-unix
# End:
#
# vim: expandtab shiftwidth=4:
