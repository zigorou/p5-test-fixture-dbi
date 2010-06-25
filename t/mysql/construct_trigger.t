use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Exception;
use Test::Fixture::DBI qw(:all);
use Test::Fixture::DBI::Connector::mysql;

sub setup_test {
    my $dbh = shift;
    $dbh->do( 'DROP DATABASE test' );
    $dbh->do( 'CREATE DATABASE test' );
    $dbh->do( 'USE test' );
}

my $connector = 'Test::Fixture::DBI::Connector::mysql';
my ( $dbh, $mysqld ) = $connector->dbh;

subtest 'default' => sub {
    setup_test( $dbh );

    my $database = construct_database(
        dbh => $dbh,
        database => 't/mysql/schema.yaml',
    );

    my $triggers;
    lives_ok(
        sub {
            $triggers = construct_trigger(
                dbh => $dbh,
                database => 't/mysql/schema.yaml',
            );
        },
        'construct_trigger will be success'
    );
    note explain $triggers;
    
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
