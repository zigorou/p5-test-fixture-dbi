use inc::Module::Install;
name 'Test-Fixture-DBI';
all_from 'lib/Test/Fixture/DBI.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
