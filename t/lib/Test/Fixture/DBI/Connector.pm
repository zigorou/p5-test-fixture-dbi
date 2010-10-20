package Test::Fixture::DBI::Connector;

use strict;
use warnings;
use lib 't/lib';
use Carp;
use Exporter qw(import);
use SQL::SplitStatement;
use Test::More;

our $VERSION = '0.01';
our @EXPORT_OK = qw(test_schema test_procedure test_function test_trigger test_index);
our %EXPORT_TAGS = ( all => [ @EXPORT_OK ] );

sub setup_database {
    my ( $class, $dbh, $statements ) = @_;
    
    for my $stmt ( @$statements ) {
        $dbh->do( $stmt ) or croak($dbh->errstr);
    }
}

sub test_schema {
    my ( $def, $expected_schema, $expected_like_data) = @_;

    subtest sprintf('test_schema (%s)', $expected_schema) => sub {
        is( $def->{schema}, $expected_schema, sprintf('schema is "%s"', $expected_schema) );
        like( $def->{data}, qr/$expected_like_data/, sprintf('data like qr/%s/', $expected_like_data) );
        note( $def->{data} );
        done_testing;
    };
}

sub test_procedure {
    my ( $def, $expected_procedure, $expected_like_data) = @_;

    subtest sprintf('test_procedure (%s)', $expected_procedure) => sub {
        is( $def->{procedure}, $expected_procedure, sprintf('procedure is "%s"', $expected_procedure) );
        like( $def->{data}, qr/$expected_like_data/, sprintf('data like qr/%s/', $expected_like_data) );
        note( $def->{data} );
        done_testing;
    };
}

sub test_function {
    my ( $def, $expected_function, $expected_like_data) = @_;

    subtest sprintf('test_function (%s)', $expected_function) => sub {
        is( $def->{function}, $expected_function, sprintf('function is "%s"', $expected_function) );
        like( $def->{data}, qr/$expected_like_data/, sprintf('data like qr/%s/', $expected_like_data) );
        note( $def->{data} );
        done_testing;
    };
}

sub test_trigger {
    my ( $def, $expected_trigger, $expected_refer, $expected_like_data) = @_;

    subtest sprintf('test_trigger (%s)', $expected_trigger) => sub {
        is( $def->{trigger}, $expected_trigger, sprintf('trigger is "%s"', $expected_trigger) );
        is( $def->{refer}, $expected_refer, sprintf('refer is "%s"', $expected_refer) );
        like( $def->{data}, qr/$expected_like_data/, sprintf('data like qr/%s/', $expected_like_data) );
        note( $def->{data} );
        done_testing;
    };
}

sub test_index {
    my ( $def, $expected_index, $expected_refer, $expected_like_data) = @_;

    subtest sprintf('test_index (%s)', $expected_index) => sub {
        is( $def->{index}, $expected_index, sprintf('index is "%s"', $expected_index) );
        is( $def->{refer}, $expected_refer, sprintf('refer is "%s"', $expected_refer) );
        like( $def->{data}, qr/$expected_like_data/, sprintf('data like qr/%s/', $expected_like_data) );
        note( $def->{data} );
        done_testing;
    };
}

1;

__END__

=head1 NAME

Test::Fixture::DBI::Connector - write short description for Test::Fixture::DBI::Connector

=head1 SYNOPSIS

  use Test::Fixture::DBI::Connector;

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
