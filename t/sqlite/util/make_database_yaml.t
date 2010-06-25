use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fixture::DBI::Util;
use Test::Fixture::DBI::Connector qw(:all);
use Test::Fixture::DBI::Connector::SQLite;

my $conn = 'Test::Fixture::DBI::Connector::SQLite';
my $dbh = $conn->dbh;
$conn->setup_database( $dbh, <<'SQL' );
CREATE TABLE people (
  id INTEGER PRIMARY KEY NOT NULL,
  nickname TEXT NOT NULL,
  status INTEGER NOT NULL DEFAULT 0,
  created_on TEXT NOT NULL,
  updated_on TEXT NOT NULL
);

CREATE TABLE people_counter (
  counter INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE friend (
  id INTEGER NOT NULL,
  friend_id INTEGER NOT NULL,
  status INTEGER NOT NULL DEFAULT 0,
  created_on TEXT NOT NULL,
  updated_on TEXT NOT NULL,
  PRIMARY KEY (id, friend_id)
);

INSERT INTO people_counter( counter ) VALUES (0);

/*
CREATE PROCEDURE proc_get_people_counter()
BEGIN
  SELECT counter FROM people_counter;
END;

CREATE FUNCTION func_hello_world() RETURNS VARCHAR(32)
RETURN 'Hello world';
*/

CREATE TRIGGER on_after_insert_people AFTER INSERT ON people
FOR EACH ROW BEGIN
  UPDATE people_counter SET counter = counter + 1;
END;

CREATE TRIGGER on_after_delete_people AFTER DELETE ON people
FOR EACH ROW BEGIN
  UPDATE people_counter SET counter = counter - 1;
END;

CREATE INDEX idx_people_on_nickname ON people (nickname);
CREATE INDEX idx_people_on_id_and_created_on ON people (id, created_on);
CREATE INDEX idx_people_on_id_and_updated_on ON people (id, updated_on);
SQL

my $database = make_database_yaml( $dbh );

subtest 'test schemas' => sub {
    test_schema( $database->[0], 'friend', 'CREATE TABLE friend ' );
    test_schema( $database->[1], 'people', 'CREATE TABLE people ' );
    test_schema( $database->[2], 'people_counter', 'CREATE TABLE people_counter ' );
    done_testing;
};

subtest 'test triggers' => sub {
    test_trigger( $database->[3], 'on_after_delete_people', 'people', 'CREATE TRIGGER on_after_delete_people ' );
    test_trigger( $database->[4], 'on_after_insert_people', 'people', 'CREATE TRIGGER on_after_insert_people ' );
    done_testing;
};

subtest 'test indexes' => sub {
    test_index( $database->[5], 'idx_people_on_id_and_created_on', 'people', 'CREATE INDEX idx_people_on_id_and_created_on ' );
    test_index( $database->[6], 'idx_people_on_id_and_updated_on', 'people', 'CREATE INDEX idx_people_on_id_and_updated_on ' );
    test_index( $database->[7], 'idx_people_on_nickname', 'people', 'CREATE INDEX idx_people_on_nickname ' );
    done_testing;
};

make_database_yaml( $dbh, './t/sqlite/schema.yaml' );

done_testing;

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# coding: utf-8-unix
# End:
#
# vim: expandtab shiftwidth=4:
