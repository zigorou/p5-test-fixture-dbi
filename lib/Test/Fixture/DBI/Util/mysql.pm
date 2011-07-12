package Test::Fixture::DBI::Util::mysql;

use strict;
use warnings;

use DBI;

our $VERSION = '0.02';

sub make_database {
    my ( $class, $dbh ) = @_;

    my @database;
    push( @database, $class->_tables($dbh) );
    push( @database, $class->_procedures($dbh) );
    push( @database, $class->_functions($dbh) );
    push( @database, $class->_triggers($dbh) );
    push( @database, $class->_events($dbh) );

    return \@database;
}

sub _tables {
    my ( $class, $dbh ) = @_;
    my @tables =
      map { $_->[0] } @{ $dbh->selectall_arrayref( q|SHOW TABLES|, ) };
    my @data;
    for my $table ( sort { $a cmp $b } @tables ) {
        my ( $schema, $data ) =
          $dbh->selectrow_array( sprintf( q|SHOW CREATE TABLE %s|, $table ) );
        push(
            @data,
            +{
                schema => $schema,
                data   => $data,
            }
        );
    }
    return @data;
}

sub _procedures {
    my ( $class, $dbh ) = @_;
    my $dbname = _dbname($dbh);

    my $rows =
      $dbh->selectall_arrayref( 'SHOW PROCEDURE STATUS', +{ Slice => +{} } );
    my @data;
    for my $row (
        sort { $a->{Name} cmp $b->{Name} }
        grep { $_->{Db} eq $dbname } @$rows
      )
    {
        my $def = $dbh->selectrow_hashref(
            sprintf( 'SHOW CREATE PROCEDURE %s', $row->{Name} ) );
        push(
            @data,
            +{
                procedure => $row->{Name},
                data => $class->_remove_definer( $def->{'Create Procedure'} ),
            }
        );
    }

    return @data;
}

sub _functions {
    my ( $class, $dbh ) = @_;
    my $dbname = _dbname($dbh);

    my $rows =
      $dbh->selectall_arrayref( 'SHOW FUNCTION STATUS', +{ Slice => +{} } );
    my @data;
    for my $row (
        sort { $a->{Name} cmp $b->{Name} }
        grep { $_->{Db} eq $dbname } @$rows
      )
    {
        my $def = $dbh->selectrow_hashref(
            sprintf( 'SHOW CREATE FUNCTION %s', $row->{Name} ) );
        push(
            @data,
            +{
                function => $row->{Name},
                data => $class->_remove_definer( $def->{'Create Function'} ),
            }
        );
    }

    return @data;
}

sub _triggers {
    my ( $class, $dbh ) = @_;

    my ( $is_enable_show_create_trigger ) = $dbh->selectrow_array( 'SELECT VERSION() >= 5.1' );

    unless ( $is_enable_show_create_trigger ) {
        return ();
    }

    my $rows = $dbh->selectall_arrayref( 'SHOW TRIGGERS', +{ Slice => +{} } );
    my @data;
    for my $row ( sort { $a->{Trigger} cmp $b->{Trigger} } @$rows ) {
        my $def = $dbh->selectrow_hashref(
            sprintf( 'SHOW CREATE TRIGGER %s', $row->{Trigger} ) );
        push(
            @data,
            +{
                trigger => $row->{Trigger},
                refer   => $row->{Table},
                data =>
                  $class->_remove_definer( $def->{'SQL Original Statement'} ),
            }
        );
    }

    return @data;
}

sub _events {
    my ( $class, $dbh ) = @_;

    my ( $is_enable_show_create_events ) = $dbh->selectrow_array( 'SELECT VERSION() >= 5.1' );

    unless ( $is_enable_show_create_events ) {
        return ();
    }

    my $rows = $dbh->selectall_arrayref( 'SHOW EVENTS', +{ Slice => +{} } );
    my @data;
    for my $row ( sort { $a->{Name} cmp $b->{Name} } @$rows ) {
        my $def = $dbh->selectrow_hashref( sprintf( 'SHOW CREATE EVENT %s', $row->{Name} ) );
        push(
            @data,
            +{
                name           => $row->{Name},
                interval_val   => $row->{'Interval value'},
                interval_field => $row->{'Interval field'},
                data           => $def->{'Create Event'},
            }
        );
    }

    return @data;
}

sub _remove_definer {
    my ( $class, $def ) = @_;
    $def =~ s/CREATE(\s*.*\s*)(PROCEDURE|FUNCTION|TRIGGER)/CREATE $2/i;
    $def;
}

sub _dbname {
    my $dbh = shift;
    my %dsn = map { split( '=', $_, 2 ) } split( ';', $dbh->{Name} );
    return exists $dsn{dbname} ? $dsn{dbname} : $dsn{db};
}

1;

__END__

=head1 NAME

Test::Fixture::DBI::Util::mysql - retrieve database definition for mysql

=head1 SYNOPSIS

  use Test::Fixture::DBI::Util::mysql;

=head1 DESCRIPTION

=head1 METHODS

=head2 make_database()

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
