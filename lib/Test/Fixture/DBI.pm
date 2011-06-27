package Test::Fixture::DBI;

use strict;
use warnings;

our $VERSION = '0.06';

use Carp;
use Exporter qw(import);
use Scalar::Util qw(blessed);
use SQL::Abstract;
use SQL::Abstract::Plugin::InsertMulti;

our @EXPORT      = qw(construct_database construct_fixture);
our @EXPORT_OK   = qw( construct_trigger );
our %EXPORT_TAGS = (
    default => [@EXPORT],
    all     => [ @EXPORT, @EXPORT_OK ],
);

sub _SCALAR { 1 };
sub _ARRAYREF { 1 << 1; };
sub _HASHREF { 1 << 2; };
sub _OBJECT { 1 << 3; };

sub _validate_with {
    my %def = @_;

    my %params = @{$def{params}};
    my %specs   = %{$def{spec}};

    for my $field ( keys %specs ) {
	my $spec = $specs{$field};
	my $param = $params{$field};
	
	if ( exists $spec->{required} && $spec->{required} && !exists $params{$field} ) {
	    croak sprintf( '%s field is required.', $field );
	}

	if ( exists $spec->{default} && !defined $param ) {
	    $params{$field} = $spec->{default};
	}
	
	next unless ( defined $param );
	
	if ( exists $spec->{type} ) {
	    my $is_valid_type = 0;
	    
	    if ( ( $spec->{type} & _SCALAR ) == _SCALAR && !ref $param) {
		$is_valid_type = 1;
	    }
	    if ( ( $spec->{type} & _ARRAYREF ) == _ARRAYREF && ref $param eq 'ARRAY' ) {
		$is_valid_type = 1;
	    }
	    if ( ( $spec->{type} & _HASHREF ) == _HASHREF && ref $param eq 'HASH' ) {
		$is_valid_type = 1;
	    }
	    if ( ( $spec->{type} & _OBJECT ) == _OBJECT && blessed($param) ) {
		$is_valid_type = 1;
	    }

	    unless ( $is_valid_type ) {
		croak sprintf( '%s field is not valid type', $field );
	    }
	}

	if ( exists $spec->{isa} && !UNIVERSAL::isa( $param, $spec->{isa} ) ) {
	    croak sprintf( '%s field is not a %s instance', $field, $spec->{isa} );
	}

    }

    return %params;
}

sub construct_database {
    my %args = _validate_with(
        params => \@_,
        spec   => +{
            dbh => +{
                type     => _OBJECT,
                isa      => 'DBI::db',
                required => 1,
            },
            database => +{
                type     => _SCALAR | _ARRAYREF,
                required => 1,
            },
            schema => +{
                type     => _ARRAYREF,
                required => 0,
                default  => [],
            },
            procedure => +{
                type     => _ARRAYREF,
                required => 0,
                default  => [],
            },
            function => +{
                type     => _ARRAYREF,
                required => 0,
                default  => [],
            },
            event => +{
                type     => _ARRAYREF,
                required => 0,
                default  => [],
            },
            index => +{
                type     => _ARRAYREF,
                required => 0,
                default  => [],
            },
        },
    );

    unless ( exists $args{dbh} && UNIVERSAL::isa( $args{dbh}, 'DBI::db' ) ) {
	croak 'dbh field is not exists or is a DBI::db';
    }

    unless ( exists $args{database} && ( !ref $args{database} || ref $args{database} eq 'ARRAY' ) ) {
	croak 'database field is not exists or is a SCALAR or ARRAYREF';
    }
    
    my $database = _validate_database( _load_database( $args{database} ) );

    return _setup_database( $args{dbh},
        [ grep { !exists $_->{trigger} } @$database ], \%args );
}

sub _validate_database {
    my $stuff = shift;

    for my $data ( @$stuff ) {
	my @data = %$data;
	
	_validate_with(
	    params => \@data,
	    spec => +{
		schema    => +{ type => _SCALAR, required => 0, },
		procedure => +{ type => _SCALAR, required => 0, },
		function  => +{ type => _SCALAR, required => 0, },
		trigger   => +{ type => _SCALAR, required => 0, },
		event     => +{ type => _SCALAR, required => 0, },
		index     => +{ type => _SCALAR, required => 0, },
		refer     => +{ type => _SCALAR, required => 0, },
		data      => +{ type => _SCALAR, required => 1, },
	    },
	);
    }

    return $stuff;
}

sub _load_database {
    my $stuff = shift;

    if ( ref $stuff ) {
        if ( ref $stuff eq 'ARRAY' ) {
            return $stuff;
        }
        else {
            croak "invalid fixture stuff. should be ARRAY: $stuff";
        }
    }
    else {
        require YAML::Syck;
        return YAML::Syck::LoadFile($stuff);
    }
}

sub _setup_database {
    my ( $dbh, $database, $args ) = @_;

    my @databases;
    my $enable_schema_filter = @{ $args->{schema} } > 0 ? 1 : 0;

    my %tables =
      $enable_schema_filter
      ? map { $_           => undef } @{ $args->{schema} }
      : map { $_->{schema} => undef }
      grep  { exists $_->{schema} } @$database;

    for my $def (@$database) {
        next
          unless ( exists $def->{schema}
            && exists $tables{ $def->{schema} } );
        $dbh->do( $def->{data} ) or croak( $dbh->errstr );
        push( @databases, $def );
    }

    my %indexes =
      map { $_->{index} => undef }
      grep {
             exists $_->{index}
          && exists $_->{refer}
          && exists $tables{ $_->{refer} }
      } @$database;

    for my $def (@$database) {
        next
          unless ( exists $def->{index}
            && exists $tables{ $def->{refer} } );
        $dbh->do( $def->{data} ) or croak( $dbh->errstr );
        push( @databases, $def );
    }

    ### TODO: considering index for SQLite
    for my $target (qw/procedure function event/) {
        my %targets =
          @{ $args->{$target} } > 0
          ? map { $_            => undef } @{ $args->{$target} }
          : map { $_->{$target} => undef }
          grep { exists $_->{$target} } @$database;

        for my $def (@$database) {
            next
              unless ( exists $def->{$target}
                && exists $targets{ $def->{$target} } );
            $dbh->do( $def->{data} ) or croak( $dbh->errstr );
            push( @databases, $def );
        }
    }

    return \@databases;
}

sub construct_trigger {
    my %args = _validate_with(
        params => \@_,
        spec   => +{
            dbh => +{
                type     => _OBJECT,
                isa      => 'DBI::db',
                required => 1,
            },
            database => +{
                type     => _SCALAR,
                required => 0,
            },
            schema => +{
                type     => _ARRAYREF,
                required => 0,
                default  => [],
            },
        },
    );

    my $trigger = _validate_database( _load_database( $args{database} ) );
    return _setup_trigger( $args{dbh},
        [ grep { exists $_->{trigger} && exists $_->{refer} } @$trigger ],
        \%args );
}

sub _setup_trigger {
    my ( $dbh, $trigger, $args ) = @_;
    my @triggers;

    my %triggers =
      @{ $args->{schema} } > 0
      ? ( map { $_ => undef } @{ $args->{schema} } )
      : ( map { $_->{refer} => undef } @$trigger );

    for my $def (@$trigger) {
        next if ( !exists $triggers{ $def->{refer} } );
        $dbh->do( $def->{data} ) or croak( $dbh->errstr );
        push( @triggers, $def );
    }

    return \@triggers;
}

sub construct_fixture {
    my %args = _validate_with(
        params => \@_,
        spec   => +{
            dbh => +{
                type     => _OBJECT,
                isa      => 'DBI::db',
                required => 1,
            },
            fixture => +{
                type     => _SCALAR | _ARRAYREF,
                required => 1,
            },
            opts => +{
                type     => _HASHREF,
                required => 0,
                default  => +{ bulk_insert => 1, },
            },
        },
    );

    $args{fixture} = [ $args{fixture} ] unless ( ref $args{fixture} );

    # $args{opts} ||= +{ bulk_insert => 1, };

    my $fixture = _validate_fixture( _load_fixture( $args{fixture} ) );

    _delete_all( $args{dbh}, $fixture );
    return _insert( $args{dbh}, $fixture, $args{opts} );
}

sub _validate_fixture {
    my $stuff = shift;

    for my $data ( @$stuff ) {
	my @data = %$data;
	_validate_with(
	    params => \@data,
	    spec => +{
		name   => +{ type => _SCALAR, required => 1, },
		schema => +{ type => _SCALAR,    required => 1, },
		data   => +{ type => _SCALAR | _ARRAYREF | _HASHREF,    required => 1, },
	    },
	);
    }
    
    return $stuff;
}

sub _load_fixture {
    my $stuff = shift;

    if ( ref $stuff ) {
        if ( ref $stuff eq 'ARRAY' ) {
            if ( ref $stuff->[0] ) {
                return $stuff;
            }
            else {
                require YAML::Syck;
                return [ map { @{ YAML::Syck::LoadFile($_) } } @$stuff ];
            }
        }
        else {
            croak "invalid fixture stuff. should be ARRAY: $stuff";
        }
    }
    else {
        croak "invalid fixture stuff. should be ARRAY: $stuff";
    }
}

sub _delete_all {
    my ( $dbh, $fixture ) = @_;

    my %seen;
    my @schema = grep { !$seen{$_}++ } map { $_->{schema} } @$fixture;

    for my $schema (@schema) {
        $dbh->do( sprintf( 'DELETE FROM %s', $schema ) )
          or croak( $dbh->errstr );
    }
}

sub _insert {
    my ( $dbh, $fixture, $opts ) = @_;

    my %seen;
    my @schema = grep { !$seen{$_}++ } map { $_->{schema} } @$fixture;

    my $sql = SQL::Abstract->new;
    my ( $stmt, @bind );

    for my $schema (@schema) {
        my @records =
          map { $_->{data} } grep { $_->{schema} eq $schema } @$fixture;
        my @records_tmp;

        if ( $opts->{bulk_insert} ) {
            while ( ( @records_tmp = splice( @records, 0, 1000 ) ) > 0 ) {
                ( $stmt, @bind ) = $sql->insert_multi( $schema, \@records_tmp );
                $dbh->do( $stmt, undef, @bind ) or croak( $dbh->errstr );
                $dbh->commit or croak( $dbh->errstr );
            }
        }
        else {
            while ( ( @records_tmp = splice( @records, 0, 1000 ) ) > 0 ) {
                for (@records_tmp) {
                    ( $stmt, @bind ) = $sql->insert( $schema, $_ );
                    $dbh->do( $stmt, undef, @bind ) or croak( $dbh->errstr );
                }
                $dbh->commit or croak( $dbh->errstr );
            }
        }
    }

    return $fixture;
}

1;
__END__

=head1 NAME

Test::Fixture::DBI - load fixture data to database.

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Test::Fixture::DBI is fixture test library for DBI.

=head1 SETUP

Before using this module, you must create database definition and fixture data.
The following is creating database definition using L<make_database_yaml.pl>.

  $ make_database_yaml.pl -d "dbi:mysql:dbname=social;host=testdb" -u root -p password -o /path/to/schema.yaml

Next step is create fixture,

  $ make_fixture_yaml.pl -d "dbi:mysql:dbname=social;host=testdb" -u root -p password -t activity -n id \
    -e "SELECT * FROM activity WHERE app_id = 12 ORDER BY created_on DESC LIMIT 10" -o /path/to/fixture.yaml


=head1 FUNCTIONS

=head2 construct_database( %specs )

The following is %specs details

=over

=item dbh

Required parameter. dbh is L<DBI>'s DBI::db object;

=item database

Required parameter. database is ARRAYREF or SCALAR. 
specify database name.

=item schema

Optional parameter. schema is ARRAYREF. 
if schema parameter is specified, then load particular schema from database.

=item procedure

Optional parameter. procedure is ARRAYREF. 
if procedure parameter is specified, then load particular procedures from database.

=item function

Optional parameter. function is ARRAYREF. 
if function parameter is specified, then load particular functions from database.

=item index

Optional parameter. index is ARRAYREF. 
if index parameter is specified, then load particular indexes from database.

=back

=head2 construct_fixture( %specs )

The following is %specs details

=over

=item dbh

Required parameter. dbh is L<DBI>'s DBI::db object;

=item fixture

Required parameter. fixture is SCALAR or ARRAYREF, Specify fixture files.

=item opts

Optional parameter. opts is HASHREF.
opts has bulk_insert key. if the bulk_insert value is true, 
then using bulk insert on loading fixture data.

=back

=head2 construct_trigger( %specs )

The following is %specs details

=over

=item dbh

Required parameter. dbh is L<DBI>'s DBI::db object;

=item database

Optional parameter. database is SCALAR.
specify database name.

=item schema

Optional parameter. schema is ARRAYREF.
if schema parameter is specified, 
then create particular triggers related specified schema on the database.

=back

=head1 AUTHOR

Toru Yamaguchi E<lt>zigorou@cpan.orgE<gt>

Yuji Shimada E<lt>xaicron@cpan.orgE<gt>

=head1 SEE ALSO

=over

=item L<Test::Fixture::DBIC::Schema>

=item L<Test::Fixture::DBIxSkinny>

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
