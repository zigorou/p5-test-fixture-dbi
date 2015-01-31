requires 'Carp';
requires 'DBI';
requires 'Exporter';
requires 'File::Temp';
requires 'Getopt::Long';
requires 'Pod::Usage';
requires 'SQL::Abstract';
requires 'SQL::Abstract::Plugin::InsertMulti';
requires 'Scalar::Util';
requires 'UNIVERSAL::require';
requires 'YAML::Syck';
requires 'parent';

on build => sub {
    requires 'ExtUtils::MakeMaker', '6.36';
    requires 'Test::Exception';
    requires 'Test::LoadAllModules';
    requires 'Test::More';
    requires 'Test::Requires';
};
