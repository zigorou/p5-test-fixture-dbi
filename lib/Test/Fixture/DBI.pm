package Test::Fixture::DBI;

use strict;
use warnings;

our $VERSION = '0.01';

use base qw(Exporter);

use Carp;
use Kwalify;
use Params::Validate qw(:all);
use SQL::Abstract;
use SQL::Abstract::Plugin::InsertMulti;

our @EXPORT = qw(construct_database construct_fixture);

sub construct_database {
    my %args = validate_with(
        params => \@_,
        spec => +{
            dbh => +{
                type     => OBJECT,
                isa      => 'DBI::db',
                optional => 0,
            },
            database => +{
                type => SCALAR | ARRAYREF,
                optional => 0,
            },
            schemas => +{
                type => ARRAYREF,
                optional => 1,
                default => [],
            },
        },
    );

    my $database =
      _validate_database( _load_database( $args{database} ) );

    return _setup_database( $args{dbh}, $database, $args{schemas} );
}

sub _validate_database {
    my $stuff = shift;

    Kwalify::validate(
        +{
            type     => 'seq',
            sequence => [
                +{
                    type    => 'map',
                    mapping => +{
                        schema  => +{ type => 'str', required => 1, },
                        data   => +{ type => 'str', required => 1, },
                    },
                },
            ]
        },
        $stuff,
    );

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
    my ($dbh, $database, $schemas) = @_;

    my %schemas =
        ( @$schemas > 0 ) ?
            map { $_ => undef } @$schemas :
            map { $_->{schema} => undef } @$database;

    my @databases;
    
    for my $def ( @$database ) {
        next if ( !exists $schemas{$def->{schema}} );
        $dbh->do( $def->{data} ) or croak($dbh->errstr);
        push( @databases, $def );
    }

    return \@databases;
}

sub construct_fixture {
    my %args = validate_with(
        params => \@_,
        spec   => +{
            dbh => +{
                type     => OBJECT,
                isa      => 'DBI::db',
                optional => 0,
            },
            fixture => +{
                type => SCALAR | ARRAYREF,
                optional => 0,
            },
            opts => +{
                type => HASHREF,
                optional => 1,
            },
        },
    );

    $args{fixture} = [ $args{fixture} ] unless ( ref $args{fixture} );
    $args{opts} ||= +{
        bulk_insert => 1,
    };
    
    my $fixture =
      _validate_fixture( _load_fixture( $args{fixture} ) );

    _delete_all( $args{dbh}, $fixture );
    return _insert( $args{dbh}, $fixture, $args{opts} );
}

sub _validate_fixture {
    my $stuff = shift;

    Kwalify::validate(
        +{
            type     => 'seq',
            sequence => [
                +{
                    type    => 'map',
                    mapping => +{
                        name   => +{ type => 'str', required => 1, },
                        schema => +{ type => 'str', required => 1, },
                        data   => +{ type => 'any', required => 1, },
                    }
                }
            ]
        },
        $stuff,
    );

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
                return [ map { @{YAML::Syck::LoadFile($_)} } @$stuff ];
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
    my ($dbh, $fixture) = @_;

    my %seen;
    my @schemas = grep { !$seen{$_}++ } map { $_->{schema} } @$fixture;

    for my $schema ( @schemas ) {
        $dbh->do( sprintf('DELETE FROM %s', $schema) ) or croak( $dbh->errstr );
    }
}

sub _insert {
    my ($dbh, $fixture, $opts) = @_;

    my %seen;
    my @schemas = grep { !$seen{$_}++ } map { $_->{schema} } @$fixture;

    my $sql = SQL::Abstract->new;
    my ($stmt, @bind);
    
    for my $schema ( @schemas ) {
        my @records = map { $_->{data} } grep { $_->{schema} eq $schema } @$fixture;
        my @records_tmp;

        if ( $opts->{bulk_insert}) {
            while ( ( @records_tmp = splice(@records, 0, 1000) ) > 0 ) {
                ($stmt, @bind) = $sql->insert_multi( $schema, \@records_tmp );
                $dbh->do( $stmt, undef, @bind ) or croak( $dbh->errstr );
                $dbh->commit or croak( $dbh->errstr );
            }
        }
        else {
            while ( ( @records_tmp = splice(@records, 0, 1000) ) > 0 ) {
                for ( @records_tmp ) {
                    ($stmt, @bind) = $sql->insert( $schema, $_ );
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

Test::Fixture::DBI is fixture test using DBI.

=head1 FUNCTIONS

=head2 load_database( %specs )

=head2 load_fixture( %specs )

=head1 AUTHOR

Toru Yamaguchi E<lt>zigorou@cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
