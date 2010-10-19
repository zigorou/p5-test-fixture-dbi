use inc::Module::Install;
name 'Test-Fixture-DBI';
all_from 'lib/Test/Fixture/DBI.pm';

requires 'parent';
requires 'Carp';
requires 'DBI';
requires 'Exporter';
requires 'File::Temp';
requires 'Getopt::Long';
requires 'Pod::Usage';
requires 'Scalar::Util';
requires 'SQL::Abstract';
requires 'SQL::Abstract::Plugin::InsertMulti';
requires 'UNIVERSAL::require';
requires 'YAML::Syck';

tests_recursive 't';
author_tests 'xt';

install_script './script/make_database_yaml.pl';
install_script './script/make_fixture_yaml.pl';

test_requires 'SQL::SplitStatement';
test_requires 'Test::Exception';
test_requires 'Test::LoadAllModules';
test_requires 'Test::More';
test_requires 'Test::Requires';

auto_set_repository;
auto_include;

# auto_install;
WriteAll;
