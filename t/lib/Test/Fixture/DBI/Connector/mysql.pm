package Test::Fixture::DBI::Connector::mysql;

use strict;
use warnings;
use lib 't/lib';
use parent qw(Test::Fixture::DBI::Connector);

use DBI;
use Test::Requires 'Test::mysqld';
use Test::mysqld;

our $VERSION = '0.01';

sub dbh {
    my ( $class, $args ) = @_;

    my $mysqld_command;
    if ( $^O eq 'linux' ) {
        ### for mysql's rpm problem
        push( @Test::mysqld::SEARCH_PATHS, '/usr', );
        $mysqld_command = Test::mysqld::_find_program(qw/mysqld sbin/);
    }

    my $mysqld = Test::mysqld->new(
        +{
            my_cnf => +{ 'skip-networking' => '', },
            ( -x $mysqld_command ) ? ( mysqld => $mysqld_command ) : ()
        }
    );
    local $SIG{INT} = sub { kill TERM => $mysqld->pid };
    return (
        DBI->connect(
            $mysqld->dsn( dbname => 'test' ),
            'root', '', +{ AutoCommit => 0, RaiseError => 1 }
        ),
        $mysqld
    );
}

1;

__END__

=head1 NAME

Test::Fixture::DBI::Connector::mysql - write short description for Test::Fixture::DBI::Connector::mysql

=head1 SYNOPSIS

  use Test::Fixture::DBI::Connector::mysql;

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
