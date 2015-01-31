package Test::Fixture::DBI::Connector::SQLite;

use strict;
use warnings;
use lib 't/lib';
use parent qw(Test::Fixture::DBI::Connector);

use DBI;
use File::Temp qw(tempfile);
use Test::Requires 'DBD::SQLite';

our $VERSION = '0.09';

sub dbh {
    my ( $class, $args ) = @_;
    my ( undef, $filename ) = tempfile;
    $args ||= +{};
    return DBI->connect( "dbi:SQLite:dbname=$filename", '', '',
        +{ AutoCommit => 0, RaiseError => 1, %$args } );
}

1;

__END__

=head1 NAME

Test::Fixture::DBI::Connector::SQLite - write short description for Test::Fixture::DBI::Connector::SQLite

=head1 SYNOPSIS

  use Test::Fixture::DBI::Connector::SQLite;

=head1 DESCRIPTION

=head2 METHODS

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
