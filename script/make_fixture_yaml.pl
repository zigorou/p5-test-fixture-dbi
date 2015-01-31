#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use DBI;
use Getopt::Long;
use Pod::Usage;
use Test::Fixture::DBI::Util;
use YAML::Syck;

our $VERSION = 0.09;

my ( $dsn, $user, $password, $table, $name, $sql, $output, $is_man, $is_help, );

GetOptions(
    'dsn|d=s'      => \$dsn,
    'user|u=s'     => \$user,
    'password|p=s' => \$password,
    'table|t=s'    => \$table,
    'name|n=s@'    => \$name,
    'execute|e=s'  => \$sql,
    'output|o=s'   => \$output,
    'help|h'       => \$is_help,
    man            => \$is_man,
);

pod2usage(1) if ($is_help);
pod2usage( -verbose => 2 ) if ($is_man);

unless ($dsn) {
    die('dsn is mandatory option');
}

unless ($table) {
    die('table is mandatory option');
}

$user     ||= '';
$password ||= '';
$name     ||= [qw/id/];
$sql      ||= sprintf( 'SELECT * FROM %s', $table );

my $dbh = DBI->connect(
    $dsn, $user,
    $password,
    +{
        AutoCommit         => 0,
        RaiseError         => 1,
        ShowErrorStatement => 1,
        PrintError         => 0,
    }
);

my $data = make_fixture_yaml( $dbh, $table, $name, $sql, $output );

if ($data) {
    print YAML::Syck::Dump($data);
}

$dbh->disconnect;

__END__

=head1 NAME

B<make_fixture_yaml.pl> - make fixture data from existing db.

=head1 VERSION

0.01

=head1 SYNOPSIS

  Options:
    --dsn|-d            database dsn
    --user|-u           database user
    --password|-p       database password
    --table|-t          table name
    --name|-n           named columns ( multiple choice )
    --execute|-e        execute query
    --output|-o         output file name (yaml format)
    --help|-h		brief help message
    --man		full documentaion

=head1 OPTIONS

=over 4

=item B<--dsn|-d>

database dsn.

=item B<--user|-u>

database user.

=item B<--password|-p>

database password.

=item B<--table|-t>

table name

=item B<--name|-n>

named columns ( multiple choice )

=item B<--execute|-e>

execute query

=item B<--output|-o>

output file name.

=item B<--help|-h>

Print brief help message and exit

=item B<--man>

Prints the manual page and exit

=back

=head1 DESCRIPTION

write description for make_fixture_yaml.pl

=head1 AUTHOR

Toru Yamaguchi E<lt>zigorou@cpan.org<gt>

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
