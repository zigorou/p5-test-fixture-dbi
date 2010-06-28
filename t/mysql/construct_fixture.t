use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Exception;
use Test::Fixture::DBI;
use Test::Fixture::DBI::Connector::mysql;

my $connector = 'Test::Fixture::DBI::Connector::mysql';
my ( $dbh, $mysqld ) = $connector->dbh;

sub setup_test {
    my $dbh = shift;
    $dbh->do('DROP DATABASE test');
    $dbh->do('CREATE DATABASE test');
    $dbh->do('USE test');
}

subtest 'default' => sub {
    setup_test($dbh);

    my $database = construct_database(
        dbh      => $dbh,
        database => 't/mysql/schema.yaml',
        schema   => [qw/people/],
    );

    lives_ok(
        sub {
            construct_fixture(
                dbh     => $dbh,
                fixture => [
                    +{
                        name   => 'zigorou',
                        schema => 'people',
                        data   => +{
                            id         => 1,
                            nickname   => 'zigorou',
                            status     => 0,
                            created_on => '2010-06-28 12:30:30',
                            updated_on => '2010-06-28 12:35:00',
                        },
                    },
                    +{
                        name   => 'hidek',
                        schema => 'people',
                        data   => +{
                            id         => 2,
                            nickname   => 'hidek',
                            status     => 1,
                            created_on => '2010-06-28 12:30:30',
                            updated_on => '2010-06-28 12:35:00',
                        },
                    },
                    +{
                        name   => 'xaicron',
                        schema => 'people',
                        data   => +{
                            id         => 3,
                            nickname   => 'xaicron',
                            status     => 2,
                            created_on => '2010-06-28 12:30:30',
                            updated_on => '2010-06-28 12:35:00',
                        },
                    },
                ],
            );
        },
        'construct_fixture() will be success'
    );

    is_deeply(
        $dbh->selectall_arrayref(
            'SELECT id, nickname, status FROM people ORDER BY id ASC',
            +{ Slice => +{} }
        ),
        [
            +{ id => 1, nickname => 'zigorou', status => 0, },
            +{ id => 2, nickname => 'hidek',   status => 1, },
            +{ id => 3, nickname => 'xaicron', status => 2, },
        ],
        'fixture data test'
    );

    lives_ok(
        sub {
            construct_fixture(
                dbh     => $dbh,
                fixture => [
                    +{
                        name   => 'arisawa',
                        schema => 'people',
                        data   => +{
                            id         => 1,
                            nickname   => 'arisawa',
                            status     => 0,
                            created_on => '2010-06-28 12:30:30',
                            updated_on => '2010-06-28 12:35:00',
                        },
                    },
                ],
            );
        },
        'construct_fixture() will be success (re-insert)'
    );

    is_deeply(
        $dbh->selectall_arrayref(
            'SELECT id, nickname, status FROM people ORDER BY id ASC',
            +{ Slice => +{} }
        ),
        [
            +{ id => 1, nickname => 'arisawa', status => 0, },
        ],
        'fixture data test (re-insert)'
    );

    done_testing;
};

subtest 'from yaml' => sub {
    setup_test($dbh);

    my $database = construct_database(
        dbh      => $dbh,
        database => 't/mysql/schema.yaml',
        schema   => [qw/people/],
    );

    lives_ok(
        sub {
            construct_fixture(
                dbh     => $dbh,
                fixture => 't/people_fixture_001.yaml',
            );
        },
        'construct_fixture() will be success'
    );

    is_deeply(
        $dbh->selectall_arrayref(
            'SELECT id, nickname, status FROM people ORDER BY id ASC',
            +{ Slice => +{} }
        ),
        [
            +{ id => 1, nickname => 'zigorou', status => 0, },
            +{ id => 2, nickname => 'hidek',   status => 1, },
            +{ id => 3, nickname => 'xaicron', status => 2, },
        ],
        'fixture data test'
    );

    lives_ok(
        sub {
            construct_fixture(
                dbh     => $dbh,
                fixture => 't/people_fixture_002.yaml',
            );
        },
        'construct_fixture() will be success (re-insert)'
    );

    is_deeply(
        $dbh->selectall_arrayref(
            'SELECT id, nickname, status FROM people ORDER BY id ASC',
            +{ Slice => +{} }
        ),
        [
            +{ id => 1, nickname => 'arisawa', status => 0, },
        ],
        'fixture data test (re-insert)'
    );

    done_testing;
};

subtest 'multiple fixture' => sub {
    setup_test($dbh);

    my $database = construct_database(
        dbh      => $dbh,
        database => 't/mysql/schema.yaml',
        schema   => [qw/people friend/],
    );

    lives_ok(
        sub {
            construct_fixture(
                dbh => $dbh,
                fixture => [
                    +{
                        'name' => 'zigorou',
                        'data' => {
                            'nickname' => 'zigorou',
                            'status' => '0',
                            'created_on' => '2010-06-28 12:30:30',
                            'id' => '1',
                            'updated_on' => '2010-06-28 12:35:00'
                        },
                        'schema' => 'people'
                    },
                    +{
                        'name' => 'hidek',
                        'data' => {
                            'nickname' => 'hidek',
                            'status' => '1',
                            'created_on' => '2010-06-28 12:30:30',
                            'id' => '2',
                            'updated_on' => '2010-06-28 12:35:00'
                        },
                        'schema' => 'people'
                    },
                    +{
                        'name' => 'xaicron',
                        'data' => {
                            'nickname' => 'xaicron',
                            'status' => '2',
                            'created_on' => '2010-06-28 12:30:30',
                            'id' => '3',
                            'updated_on' => '2010-06-28 12:35:00'
                        },
                        'schema' => 'people'
                    },
                    +{
                        'name' => 'friend_1',
                        'data' => {
                            'created_on' => '2010-06-28 13:30:30',
                            'status' => '0',
                            'friend_id' => '1',
                            'updated_on' => '2010-06-28 13:35:00'
                        },
                        'schema' => 'friend'
                    },
                    +{
                        'name' => 'friend_2',
                        'data' => {
                            'created_on' => '2010-06-28 14:30:30',
                            'status' => '1',
                            'friend_id' => '2',
                            'updated_on' => '2010-06-28 14:35:00'
                        },
                        'schema' => 'friend'
                    },
                    +{
                        'name' => 'friend_3',
                        'data' => {
                            'created_on' => '2010-06-28 15:30:30',
                            'status' => '2',
                            'friend_id' => '3',
                            'updated_on' => '2010-06-28 15:35:00'
                        },
                        'schema' => 'friend'
                    }
                ],
            );
        },
        'construct_fixture() will be success'
    );

    is_deeply(
        $dbh->selectall_arrayref(
            'SELECT id, nickname, status FROM people ORDER BY id ASC',
            +{ Slice => +{} }
        ),
        [
            +{ id => 1, nickname => 'zigorou', status => 0, },
            +{ id => 2, nickname => 'hidek',   status => 1, },
            +{ id => 3, nickname => 'xaicron', status => 2, },
        ],
        'fixture people test'
    );

    is_deeply(
        $dbh->selectall_arrayref(
            'SELECT friend_id, status FROM friend ORDER BY friend_id ASC',
            +{ Slice => +{} },
        ),
        [
            +{ friend_id => 1, status => 0, },
            +{ friend_id => 2, status => 1, },
            +{ friend_id => 3, status => 2, },
        ],
        'fixture friend test'
    );

    done_testing;
};

subtest 'multiple fixture from yaml' => sub {
    setup_test($dbh);

    my $database = construct_database(
        dbh      => $dbh,
        database => 't/mysql/schema.yaml',
        schema   => [qw/people friend/],
    );
    
    lives_ok(
        sub {
            construct_fixture(
                dbh     => $dbh,
                fixture => [
                    't/people_fixture_001.yaml',
                    't/friend_fixture.yaml',
                ],
            );
        },
        'construct_fixture() will be success'
    );

    is_deeply(
        $dbh->selectall_arrayref(
            'SELECT id, nickname, status FROM people ORDER BY id ASC',
            +{ Slice => +{} }
        ),
        [
            +{ id => 1, nickname => 'zigorou', status => 0, },
            +{ id => 2, nickname => 'hidek',   status => 1, },
            +{ id => 3, nickname => 'xaicron', status => 2, },
        ],
        'fixture people test'
    );

    is_deeply(
        $dbh->selectall_arrayref(
            'SELECT friend_id, status FROM friend ORDER BY friend_id ASC',
            +{ Slice => +{} },
        ),
        [
            +{ friend_id => 1, status => 0, },
            +{ friend_id => 2, status => 1, },
            +{ friend_id => 3, status => 2, },
        ],
        'fixture friend test'
    );
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
