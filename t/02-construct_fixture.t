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

subtest 'setup fixture from yaml' => sub {
    lives_ok(
        sub {
            construct_fixture(
                dbh     => $dbh,
                fixture => 't/user_fixture_001.yaml',
                opts    => +{ bulk_insert => 0, },
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
                fixture => 't/user_fixture_002.yaml',
                opts    => +{ bulk_insert => 0, },
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

subtest 'setup multiple fixture' => sub {
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
                    +{
                        name   => 'diary1',
                        schema => 'diary',
                        data   => +{
                            id        => 1,
                            writer_id => 1,
                            subject   => 'diary1',
                            text      => 'foofoofoo',
                        },
                    },
                    +{
                        name   => 'diary2',
                        schema => 'diary',
                        data   => +{
                            id        => 2,
                            writer_id => 3,
                            subject   => 'diary2',
                            text      => 'barbarbar',
                        },
                    },
                    +{
                        name   => 'comment1_1',
                        schema => 'comment',
                        data   => +{
                            id        => 1,
                            diary_id  => 1,
                            writer_id => 2,
                            text      => 'bazbazbaz',
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
        'setup user fixture'
    );

    my $diaries = $dbh->selectall_arrayref( q|SELECT * FROM diary ORDER BY id|,
        +{ Slice => +{} } );

    is_deeply(
        $diaries,
        [
            +{
                id        => 1,
                writer_id => 1,
                subject   => 'diary1',
                text      => 'foofoofoo',
            },
            +{
                id        => 2,
                writer_id => 3,
                subject   => 'diary2',
                text      => 'barbarbar',
            },
        ],
        'setup diary fixture'
    );

    my $comments =
      $dbh->selectall_arrayref( q|SELECT * FROM comment ORDER BY id|,
        +{ Slice => +{} } );

    is_deeply(
        $comments,
        [
            +{
                id        => 1,
                diary_id  => 1,
                writer_id => 2,
                text      => 'bazbazbaz',
            },
        ],
        'setup comment fixture'
    );

    done_testing;
};

subtest 'setup multiple fixture from yaml' => sub {
    lives_ok(
        sub {
            construct_fixture(
                dbh     => $dbh,
                fixture => [
                    't/user_fixture_001.yaml',
                    't/diary_fixture.yaml',
                    't/comment_fixture.yaml',
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
        'setup user fixture'
    );

    my $diaries = $dbh->selectall_arrayref( q|SELECT * FROM diary ORDER BY id|,
        +{ Slice => +{} } );

    is_deeply(
        $diaries,
        [
            +{
                id        => 1,
                writer_id => 1,
                subject   => 'diary1',
                text      => 'foofoofoo',
            },
            +{
                id        => 2,
                writer_id => 3,
                subject   => 'diary2',
                text      => 'barbarbar',
            },
        ],
        'setup diary fixture'
    );

    my $comments =
      $dbh->selectall_arrayref( q|SELECT * FROM comment ORDER BY id|,
        +{ Slice => +{} } );

    is_deeply(
        $comments,
        [
            +{
                id        => 1,
                diary_id  => 1,
                writer_id => 2,
                text      => 'bazbazbaz',
            },
        ],
        'setup comment fixture'
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
