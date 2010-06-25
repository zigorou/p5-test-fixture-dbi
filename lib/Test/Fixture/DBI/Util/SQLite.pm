package Test::Fixture::DBI::Util::SQLite;

use strict;
use warnings;

our $VERSION = '0.01';

sub make_database {
    my ( $class, $dbh ) = @_;

    my $rows = $dbh->selectall_arrayref(
        q|SELECT name, type, tbl_name, sql FROM sqlite_master WHERE sql IS NOT NULL ORDER BY type|,
        +{ Slice => +{} },
    );

    my @database;

    ### retrieve table and view
    push(
        @database,
        map { +{ schema => $_->{name}, data => $_->{sql}, } }
        sort { $a->{type} cmp $b->{type} || $a->{name} cmp $b->{name} } 
        grep { $_->{type} eq 'table' || $_->{type} eq 'view' }
        @$rows
    );

    ### retrive trigger
    push(
        @database,
        sort { $a->{trigger} cmp $b->{trigger} }
        map { +{ trigger => $_->{name}, refer => $_->{tbl_name}, data => $_->{sql}, } }
        grep { $_->{type} eq 'trigger' }
        @$rows
    );

    ### retrive index
    push(
        @database,
        sort { $a->{index} cmp $b->{index} }
        map { +{ index => $_->{name}, refer => $_->{tbl_name}, data => $_->{sql}, } }
        grep { $_->{type} eq 'index' }
        @$rows
    );
    
    return \@database;
}

1;

__END__

=head1 NAME

Test::Fixture::DBI::Util::mysql - write short description for Test::Fixture::DBI::Util::mysql

=head1 SYNOPSIS

  use Test::Fixture::DBI::Util::mysql;

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
