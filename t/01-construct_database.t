use strict;
use warnings;

use DBI;
use Test::More;
use Test::Exception;
use Test::Requires 'DBD::SQLite';
use File::Temp qw/tempfile/;
use Test::Fixture::DBI;

subtest 'setup all tables' => sub {
    my ( undef, $filename ) = tempfile;
    my $dbh =
      DBI->connect( "dbi:SQLite:dbname=$filename", '', '',
        +{ AutoCommit => 0, RaiseError => 1 } );

    lives_ok(
        sub {
            construct_database(
                dbh      => $dbh,
                database => [
                    +{
                        schema => 'diary',
                        data =>
q|CREATE TABLE diary ( id INTEGER PRIMARY KEY NOT NULL, subject VARCHAR(32), text VARCHAR(1024) );|,
                    },
                    +{
                        schema => 'comment',
                        data =>
q|CREATE TABLE comment ( id INTEGER PRIMARY KEY NOT NULL, diary_id INTEGER NOT NULL, text VARCHAR(128) );|,
                    },
                    +{
                        schema => 'user',
                        data =>
q|CREATE TABLE user (id INTEGER PRIMARY KEY NOT NULL, name VARCHAR(32) )|,
                    },
                ],
            );
        },
        'construct_database is success'
    );

    my $tables = [
        map { $_->[0] } @{
            $dbh->selectall_arrayref(
q|SELECT name FROM sqlite_master WHERE type = ? UNION ALL SELECT name FROM sqlite_temp_master WHERE type = ? ORDER BY name|,
                undef, 'table', 'table'
            )
          }
    ];

    is_deeply( $tables, [qw/comment diary user/], 'setup schemas' );

    $dbh->disconnect;

    done_testing;
};

subtest 'setup all tables from yaml' => sub {
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
        'construct_database is success'
    );

    my $tables = [
        map { $_->[0] } @{
            $dbh->selectall_arrayref(
q|SELECT name FROM sqlite_master WHERE type = ? ORDER BY name|,
                undef, 'table'
            )
          }
    ];

    is_deeply( $tables, [qw/comment diary user/], 'setup schemas' );

    $dbh->disconnect;

    done_testing;
};

subtest 'setup specified tables' => sub {
    my ( undef, $filename ) = tempfile;
    my $dbh =
      DBI->connect( "dbi:SQLite:dbname=$filename", '', '',
        +{ AutoCommit => 0, RaiseError => 1 } );

    lives_ok(
        sub {
            construct_database(
                dbh      => $dbh,
                database => [
                    +{
                        schema => 'diary',
                        data =>
q|CREATE TABLE diary ( id INTEGER PRIMARY KEY NOT NULL, subject VARCHAR(32), text VARCHAR(1024) );|,
                    },
                    +{
                        schema => 'comment',
                        data =>
q|CREATE TABLE comment ( id INTEGER PRIMARY KEY NOT NULL, diary_id INTEGER NOT NULL, text VARCHAR(128) );|,
                    },
                    +{
                        schema => 'user',
                        data =>
q|CREATE TABLE user (id INTEGER PRIMARY KEY NOT NULL, name VARCHAR(32) )|,
                    },
                ],
                schemas => [qw/diary comment/]
            );
        },
        'construct_database is success'
    );

    my $tables = [
        map { $_->[0] } @{
            $dbh->selectall_arrayref(
q|SELECT name FROM sqlite_master WHERE type = ? UNION ALL SELECT name FROM sqlite_temp_master WHERE type = ? ORDER BY name|,
                undef, 'table', 'table'
            )
          }
    ];

    is_deeply( $tables, [qw/comment diary/], 'setup schemas' );

    $dbh->disconnect;

    done_testing;
};

subtest 'setup specified tables from yaml' => sub {
    my ( undef, $filename ) = tempfile;
    my $dbh =
      DBI->connect( "dbi:SQLite:dbname=$filename", '', '',
        +{ AutoCommit => 0, RaiseError => 1 } );

    lives_ok(
        sub {
            construct_database(
                dbh      => $dbh,
                database => 't/schema.yaml',
                schemas  => [qw/diary comment/]
            );
        },
        'construct_database is success'
    );

    my $tables = [
        map { $_->[0] } @{
            $dbh->selectall_arrayref(
q|SELECT name FROM sqlite_master WHERE type = ? UNION ALL SELECT name FROM sqlite_temp_master WHERE type = ? ORDER BY name|,
                undef, 'table', 'table'
            )
          }
    ];

    is_deeply( $tables, [qw/comment diary/], 'setup schemas' );

    $dbh->disconnect;

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
