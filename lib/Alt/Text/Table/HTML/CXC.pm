package Alt::Text::Table::HTML::CXC;

use Alt::Assert;

# ABSTRACT: Alternate CXC version of Text::Table::HTML

our $VERSION = 0.101;
1;

__END__

=head1 NAME

Alt::Text::Table::HTML::CXC

=head1 SYNTAX

 use Text::Table::HTML;

 # do this to ensure the Alt version is loaded.
 use Alt::Text::Table::HTML::CXC;

=head1 DESCRIPTION

This module is a means of using a patched version of
L<Text::Table::HTML>.

See L</Text::Table::HTML> for more information.

Use this module as

=over

=item *

A dependency in
F<dist.ini>, F<cpanfile>, F<Makefile.PL>, F<META.yml>  or whatever you use to track dependencies.

Don't depend on L<Text::Table::HTML>.

=item *

A means of asserting that the C<Alt> version is what has been loaded.

=back

=head1 AUTHOR

Diab Jerius E<lt>djerius@cpan.orgE<gt>

