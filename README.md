# NAME

Test::Fixture::DBI - load fixture data to database.

# SYNOPSIS

    use DBI;
    use File::Temp qw(tempfile);
    use Test::More;
    use Test::Fixture::DBI;

    my ( undef, $filename ) = tempfile;
    my $dbh = DBI->connect( "dbi:SQLite:dbname=$filename", "", "" );

    construct_database(
      dbh => $dbh,
      database => '/path/to/schema.yaml',
    );

    construct_fixture(
      dbh => $dbh,
      fixture => '/path/to/fixture.yaml',
    );

# DESCRIPTION

Test::Fixture::DBI is fixture test library for DBI.

# SETUP

Before using this module, you must create database definition and fixture data.
The following is creating database definition using [make\_database\_yaml.pl](https://metacpan.org/pod/make_database_yaml.pl).

    $ make_database_yaml.pl -d "dbi:mysql:dbname=social;host=testdb" -u root -p password -o /path/to/schema.yaml

Next step is create fixture,

    $ make_fixture_yaml.pl -d "dbi:mysql:dbname=social;host=testdb" -u root -p password -t activity -n id \
      -e "SELECT * FROM activity WHERE app_id = 12 ORDER BY created_on DESC LIMIT 10" -o /path/to/fixture.yaml

# FUNCTIONS

## construct\_database( %specs )

The following is %specs details

- dbh

    Required parameter. dbh is [DBI](https://metacpan.org/pod/DBI)'s DBI::db object;

- database

    Required parameter. database is ARRAYREF or SCALAR. 
    specify database name.

- schema

    Optional parameter. schema is ARRAYREF. 
    if schema parameter is specified, then load particular schema from database.

- procedure

    Optional parameter. procedure is ARRAYREF. 
    if procedure parameter is specified, then load particular procedures from database.

- function

    Optional parameter. function is ARRAYREF. 
    if function parameter is specified, then load particular functions from database.

- index

    Optional parameter. index is ARRAYREF. 
    if index parameter is specified, then load particular indexes from database.

## construct\_fixture( %specs )

The following is %specs details

- dbh

    Required parameter. dbh is [DBI](https://metacpan.org/pod/DBI)'s DBI::db object;

- fixture

    Required parameter. fixture is SCALAR or ARRAYREF, Specify fixture files.

- opts

    Optional parameter. opts is HASHREF.
    opts has bulk\_insert key. if the bulk\_insert value is true, 
    then using bulk insert on loading fixture data.

## construct\_trigger( %specs )

The following is %specs details

- dbh

    Required parameter. dbh is [DBI](https://metacpan.org/pod/DBI)'s DBI::db object;

- database

    Optional parameter. database is SCALAR.
    specify database name.

- schema

    Optional parameter. schema is ARRAYREF.
    if schema parameter is specified, 
    then create particular triggers related specified schema on the database.

# AUTHOR

Toru Yamaguchi <zigorou@cpan.org>

Yuji Shimada <xaicron@cpan.org>

# SEE ALSO

- [Test::Fixture::DBIC::Schema](https://metacpan.org/pod/Test::Fixture::DBIC::Schema)
- [Test::Fixture::DBIxSkinny](https://metacpan.org/pod/Test::Fixture::DBIxSkinny)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
