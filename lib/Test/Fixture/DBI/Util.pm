package Test::Fixture::DBI::Util;

use strict;
use warnings;

use base qw(Exporter);

use Carp;
use DBI;
use YAML::Syck;

our $VERSION = '0.01';
our @EXPORT = qw(make_database_yaml make_fixture_yaml);

sub make_database_yaml {
    my ($dbh, $filename) = @_;
    my $driver = $dbh->{Driver}{Name};
    my $generator = __PACKAGE__->can('_make_database_yaml_' . $driver);

    unless ( $generator ) {
        croak( sprintf('Driver %s is not supported yet', $driver) );
    }

    my $data = $generator->( $dbh );

    if ( $filename ) {
        YAML::Syck::DumpFile( $filename, $data );
    }
    else {
        print YAML::Syck::Dump( $data );
    }
}

sub make_fixture_yaml {
    my ($dbh, $schema, $name_column, $sql, $filename) = @_;
    my $rows = $dbh->selectall_arrayref( $sql, +{ Slice => +{} } );

    my @data;
    for my $row ( @$rows ) {
        push(@data, +{
            name => ref $name_column ? join('_', map { $row->{$_} } @$name_column ) : $row->{$name_column},
            schema => $schema,
            data => $row,
        });
    }

    if ( $filename ) {
        YAML::Syck::DumpFile( $filename, \@data );
    }
    else {
        YAML::Syck::Dump( $filename );
    }
}

sub _make_database_yaml_SQLite {
    my $dbh = shift;

    my $rows = $dbh->selectall_arrayref(
        q|SELECT tbl_name AS schema, sql AS data FROM sqlite_master WHERE type = ? ORDER BY tbl_name|,
        +{ Slice => +{} },
        'table'
    );

    return $rows;
}

sub _make_database_yaml_mysql {
    my $dbh = shift;

    my @tables = map { $_->[0] } @{$dbh->selectall_arrayref(
        q|SHOW TABLES|,
    )};

    my @data;
    
    for my $table ( @tables ) {
        my ($schema, $data) = $dbh->selectrow_array( sprintf(q|SHOW CREATE TABLE %s|, $table) );
        push( @data, +{
            schema => $schema,
            data   => $data,
        } );
    }

    return \@data;
}

1;

__END__

=head1 NAME

Test::Fixuture::DBI::Util - Make schema and fixture from exists database.

=head1 SYNOPSIS

  use Test::Fixuture::DBI::Util;

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 make_database_yaml()

=head2 make_fixture_yaml()

=head1 AUTHOR

Toru Yamaguchi E<lt>zigorou@cpan.org<gt>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.

=head1 SEE ALSO

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# coding: utf-8-unix
# End:
#
# vim: expandtab shiftwidth=4:
