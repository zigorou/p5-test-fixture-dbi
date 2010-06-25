package Test::Fixture::DBI;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp;
use Exporter qw(import);
use Kwalify;
use Params::Validate qw(:all);
use SQL::Abstract;
use SQL::Abstract::Plugin::InsertMulti;

our @EXPORT      = qw(construct_database construct_fixture);
our @EXPORT_OK   = qw( construct_trigger );
our %EXPORT_TAGS = (
    default => [@EXPORT],
    all     => [ @EXPORT, @EXPORT_OK ]
);

sub construct_database {
    my %args = validate_with(
        params => \@_,
        spec   => +{
            dbh => +{
                type     => OBJECT,
                isa      => 'DBI::db',
                required => 1,
            },
            database => +{
                type     => SCALAR | ARRAYREF,
                required => 1,
            },
            schema => +{
                type     => ARRAYREF,
                required => 0,
                default  => [],
            },
            procedure => +{
                type     => ARRAYREF,
                required => 0,
                default  => [],
            },
            function => +{
                type     => ARRAYREF,
                required => 0,
                default  => [],
            },
            index => +{
                type     => ARRAYREF,
                required => 0,
                default  => [],
            },
        },
    );

    my $database = _validate_database( _load_database( $args{database} ) );

    return _setup_database( $args{dbh},
        [ grep { !exists $_->{trigger} } @$database ], \%args );
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
                        schema    => +{ type => 'str', required => 0, },
                        procedure => +{ type => 'str', required => 0, },
                        function  => +{ type => 'str', required => 0, },
                        trigger   => +{ type => 'str', required => 0, },
                        index     => +{ type => 'str', required => 0, },
                        refer     => +{ type => 'str', required => 0, },
                        data      => +{ type => 'str', required => 1, },
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
    for my $target (qw/procedure function/) {
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
    my %args = validate_with(
        params => \@_,
        spec   => +{
            dbh => +{
                type     => OBJECT,
                isa      => 'DBI::db',
                required => 1,
            },
            database => +{
                type     => SCALAR,
                required => 0,
            },
            schema => +{
                type     => ARRAYREF,
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
    my %args = validate_with(
        params => \@_,
        spec   => +{
            dbh => +{
                type     => OBJECT,
                isa      => 'DBI::db',
                required => 1,
            },
            fixture => +{
                type     => SCALAR | ARRAYREF,
                required => 1,
            },
            opts => +{
                type     => HASHREF,
                required => 0,
            },
        },
    );

    $args{fixture} = [ $args{fixture} ] unless ( ref $args{fixture} );
    $args{opts} ||= +{ bulk_insert => 1, };

    my $fixture = _validate_fixture( _load_fixture( $args{fixture} ) );

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
                        name   => +{ type => 'scalar', required => 1, },
                        schema => +{ type => 'str',    required => 1, },
                        data   => +{ type => 'any',    required => 1, },
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
