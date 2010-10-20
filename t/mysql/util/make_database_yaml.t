use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fixture::DBI::Util;
use Test::Fixture::DBI::Connector qw(:all);
use Test::Fixture::DBI::Connector::mysql;

my $conn = 'Test::Fixture::DBI::Connector::mysql';
my ( $dbh, $mysqld ) = $conn->dbh;
$dbh->{ShowErrorStatement} = 1;

my @statements = (
    << 'SQL',
CREATE TABLE people (
  id int PRIMARY KEY NOT NULL,
  nickname varchar(32) NOT NULL,
  status int NOT NULL DEFAULT 0,
  created_on datetime NOT NULL,
  updated_on datetime NOT NULL
) ENGINE=InnoDB;
SQL
    << 'SQL',
CREATE TABLE people_counter (
  counter int NOT NULL DEFAULT 0
) ENGINE=MyISAM;
SQL
    << 'SQL',
CREATE TABLE friend (
  id int NOT NULL,
  friend_id int NOT NULL,
  status int NOT NULL DEFAULT 0,
  created_on datetime NOT NULL,
  updated_on datetime NOT NULL,
  PRIMARY KEY (id, friend_id)
) ENGINE=InnoDB;
SQL
    'INSERT INTO people_counter( counter ) VALUES (0)',
    << 'SQL',
CREATE PROCEDURE proc_get_people_counter()
  BEGIN
    SELECT counter FROM people_counter;
  END;
SQL
    << 'SQL',
CREATE TRIGGER on_after_insert_people AFTER INSERT ON people
  FOR EACH ROW BEGIN
    UPDATE people_counter SET counter = counter + 1;
  END;
SQL
    << 'SQL',
CREATE TRIGGER on_after_delete_people AFTER DELETE ON people
  FOR EACH ROW BEGIN
    UPDATE people_counter SET counter = counter - 1;
  END;
SQL
    'CREATE INDEX idx_people_on_nickname ON people (nickname);',
    'CREATE INDEX idx_people_on_id_and_created_on ON people (id, created_on);',
    'CREATE INDEX idx_people_on_id_and_updated_on ON people (id, updated_on);',
    << 'SQL',
CREATE FUNCTION func_hello_world() RETURNS VARCHAR(32)
  RETURN 'Hello world';
SQL
);

$conn->setup_database( $dbh, \@statements );
$dbh->commit;

my $database = make_database_yaml($dbh);

subtest 'test schemas' => sub {
    test_schema( $database->[0], 'friend', 'CREATE TABLE `friend` ' );
    test_schema( $database->[1], 'people', 'CREATE TABLE `people` ' );
    test_schema( $database->[2], 'people_counter',
        'CREATE TABLE `people_counter` ' );
    done_testing;
};

subtest 'test procedures' => sub {
    test_procedure( $database->[3], 'proc_get_people_counter',
        'CREATE PROCEDURE `proc_get_people_counter`' );
    done_testing;
};

subtest 'test functions' => sub {
    test_function( $database->[4], 'func_hello_world',
        'CREATE FUNCTION `func_hello_world`' );
    done_testing;
};

subtest 'test triggers' => sub {
    test_trigger( $database->[5], 'on_after_delete_people', 'people',
        'CREATE TRIGGER on_after_delete_people ' );
    test_trigger( $database->[6], 'on_after_insert_people', 'people',
        'CREATE TRIGGER on_after_insert_people ' );
    done_testing;
};

$dbh->disconnect;
undef $mysqld;

done_testing;

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# coding: utf-8-unix
# End:
#
# vim: expandtab shiftwidth=4:
