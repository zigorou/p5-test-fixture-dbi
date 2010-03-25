use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Requires 'DBD::SQLite';
use File::Temp qw/tempfile/;
use Test::Fixture::DBI;

my ( undef, $filename ) = tempfile;
my $dbh =
  DBI->connect( "dbi:SQLite:dbname=$filename", '', '',
    +{ AutoCommit => 0, RaiseError => 1 } );

lives_ok(
    sub {
        construct_database(
            dbh      => $dbh,
            database => 't/schema.yaml',
        );
    },
    'construct_database() is success'
);

subtest 'setup fixture' => sub {
    lives_ok(
        sub {
            construct_fixture(
                dbh     => $dbh,
                fixture => [
                    +{
                        name   => 'zigorou',
                        schema => 'user',
                        data   => +{
                            id   => 1,
                            name => 'zigorou',
                        },
                    },
                    +{
                        name   => 'hidek',
                        schema => 'user',
                        data   => +{
                            id   => 2,
                            name => 'hidek',
                        },
                    },
                    +{
                        name   => 'crazytaxi',
                        schema => 'user',
                        data   => +{
                            id   => 3,
                            name => 'crazytaxi',
                        },
                    },
                ],
                opts => +{ bulk_insert => 0, },
            );
        },
        'construct_fixture is success'
    );

    my $users = $dbh->selectall_arrayref( q|SELECT * FROM user ORDER BY id|,
        +{ Slice => +{} } );

    is_deeply(
        $users,
        [
            +{ id => 1, name => 'zigorou' },
            +{ id => 2, name => 'hidek' },
            +{ id => 3, name => 'crazytaxi' }
        ],
        'setup fixture'
    );

    lives_ok(
        sub {
            construct_fixture(
                dbh     => $dbh,
                fixture => [
                    +{
                        name   => 'myfinder',
                        schema => 'user',
                        data   => +{
                            id   => 1,
                            name => 'myfinder',
                        },
                    },
                    +{
                        name   => 'bayashi',
                        schema => 'user',
                        data   => +{
                            id   => 2,
                            name => 'bayashi',
                        },
                    },
                ],
                opts => +{ bulk_insert => 0, },
            );
        },
        'construct_fixture is success'
    );

    $users = $dbh->selectall_arrayref( q|SELECT * FROM user ORDER BY id|,
        +{ Slice => +{} } );
    is_deeply(
        $users,
        [ +{ id => 1, name => 'myfinder' }, +{ id => 2, name => 'bayashi' } ],
        're setup fixture'
    );

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
