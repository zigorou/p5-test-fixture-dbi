use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Exception;
use Test::Fixture::DBI qw(:all);
use Test::Fixture::DBI::Connector::mysql;

sub setup_test {
    my $dbh = shift;
    $dbh->do('DROP DATABASE test');
    $dbh->do('CREATE DATABASE test');
    $dbh->do('USE test');
}

my $connector = 'Test::Fixture::DBI::Connector::mysql';
my ( $dbh, $mysqld ) = $connector->dbh;

sub test_trigger {
    my ( $dbh, $expects ) = @_;

    my $expects_triggers = +{ map { ( $_ => undef ) } @$expects };

    my $got_triggers = +{
        map { ( $_ => undef ) }
          keys %{
            $dbh->selectall_hashref( 'SHOW TRIGGERS',
                'Trigger', +{ Slice => +{} } )
          }
    };

    is_deeply( $got_triggers, $expects_triggers,
        sprintf( 'constructed triggers (%s)', join( ', ', @$expects ) ) );
}

subtest 'default' => sub {
    setup_test($dbh);

    my $database = construct_database(
        dbh      => $dbh,
        database => 't/mysql/schema.yaml',
    );

    my $triggers;
    lives_ok(
        sub {
            $triggers = construct_trigger(
                dbh      => $dbh,
                database => 't/mysql/schema.yaml',
            );
        },
        'construct_trigger will be success'
    );

    test_trigger(
        $dbh,
        [
            qw/on_after_delete_friend on_after_insert_friend on_after_delete_people on_after_insert_people/
        ]
    );

    done_testing;
};

subtest 'specified schema' => sub {
    setup_test($dbh);

    my $database = construct_database(
        dbh      => $dbh,
        database => 't/mysql/schema.yaml',
        schema => [qw/friend friend_counter/]
    );

    my $triggers;
    lives_ok(
        sub {
            $triggers = construct_trigger(
                dbh      => $dbh,
                database => 't/mysql/schema.yaml',
                schema => [qw/friend friend_counter/]
            );
        },
        'construct_trigger will be success'
    );

    test_trigger(
        $dbh,
        [
            qw/on_after_delete_friend on_after_insert_friend/
        ]
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
