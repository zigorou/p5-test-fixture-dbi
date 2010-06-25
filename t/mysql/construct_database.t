use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Exception;
use Test::Fixture::DBI;
use Test::Fixture::DBI::Connector::mysql;

sub setup_test {
    my $dbh = shift;
    $dbh->do( 'DROP DATABASE test' );
    $dbh->do( 'CREATE DATABASE test' );
    $dbh->do( 'USE test' );
}

sub test_tables {
    my ( $dbh, $expected_tables ) = @_;
    my $expected_table_map = +{
        map { ( $_ => +{ Tables_in_test => $_ } ) }
        @$expected_tables
    };

    my $got_table_map = $dbh->selectall_hashref( 'SHOW TABLES', 'Tables_in_test', +{ Slice => +{ } } );
    is_deeply( $got_table_map, $expected_table_map, sprintf( 'exists tables (%s)', join(', ', @$expected_tables) ) );
}

sub test_procedures {
    my ( $dbh, $expected_procedures ) = @_;
    $expected_procedures = [
        sort { $a cmp $b }
        @$expected_procedures
    ];
    my $rows = $dbh->selectall_arrayref( 'SHOW PROCEDURE STATUS', +{ Slice => +{ Name => undef, }, } );
    my $got_procedures = [
        sort { $a cmp $b }
        map { $_->{Name} }
        @$rows
    ];

    is_deeply( $got_procedures, $expected_procedures, sprintf('exists procedures (%s)', join( ', ', @$expected_procedures ) ) );
}

sub test_functions {
    my ( $dbh, $expected_functions ) = @_;
    $expected_functions = [
        sort { $a cmp $b }
        @$expected_functions
    ];
    my $rows = $dbh->selectall_arrayref( 'SHOW FUNCTION STATUS', +{ Slice => +{ Name => undef, }, } );
    my $got_functions = [
        sort { $a cmp $b }
        map { $_->{Name} }
        @$rows
    ];

    is_deeply( $got_functions, $expected_functions, sprintf('exists functions (%s)', join( ', ', @$expected_functions ) ) );
}

my $connector = 'Test::Fixture::DBI::Connector::mysql';
my ( $dbh, $mysqld ) = $connector->dbh;

subtest 'default' => sub {
    setup_test( $dbh );
    
    my $database;

    lives_ok(
        sub {
            $database = construct_database(
                dbh => $dbh,
                database => 't/mysql/schema.yaml',
            );
        },
        'construct_database() will be success',
    );

    test_tables( $dbh, [ qw/people people_counter friend friend_counter/ ] );
    test_procedures( $dbh, [ qw/proc_get_friend_counter proc_get_people_counter/ ] );
    test_functions( $dbh, [ qw/func_hello_world func_hello_world2/ ] );
    
    done_testing;
};

subtest 'using schama, function, procedure option' => sub {
    setup_test( $dbh );
    
    my $database;

    lives_ok(
        sub {
            $database = construct_database(
                dbh => $dbh,
                database => 't/mysql/schema.yaml',
                schema => [ qw/people/ ],
                procedure => [ qw/proc_get_people_counter/ ] ,
                function => [ qw/func_hello_world2/ ],
            );
        },
        'construct_database() will be success',
    );

    test_tables( $dbh, [ qw/people/ ] );
    test_procedures( $dbh, [ qw/proc_get_people_counter/ ] );
    test_functions( $dbh, [ qw/func_hello_world2/ ] );
    
    done_testing;
};

$dbh->disconnect;

done_testing;

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# coding: utf-8-unix
# End:
#
# vim: expandtab shiftwidth=4:
