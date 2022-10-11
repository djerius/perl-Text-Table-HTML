package Text::Table::HTML;

use 5.010001;
use strict;
use warnings;

# AUTHORITY
# DATE
# DIST
# VERSION

sub _encode {
    state $load = do { require HTML::Entities };
    HTML::Entities::encode_entities(shift);
}

sub table {
    my %params = @_;
    my $rows = $params{rows} or die "Must provide rows!";

    my $max_index = _max_array_index($rows);

    # here we go...
    my @table;

    push @table, "<table>\n";

    if (defined $params{caption}) {
        require HTML::Entities;
        push @table, "<caption>".HTML::Entities::encode_entities($params{caption})."</caption>\n";
    }

    # then the data
    my $i = -1;
    foreach my $row ( @{ $rows }[0..$#$rows] ) {
        $i++;
        my $in_header;
        if ($params{header_row}) {
            if ($i == 0) { push @table, "<thead>\n"; $in_header++ }
            if ($i == 1) { push @table, "<tbody>\n" }
        } else {
            if ($i == 1) { push @table, "<tbody>\n" }
        }

        my $has_bottom_border = grep { ref $_ eq 'HASH' && $_->{bottom_border} } @$row;

        push @table, "<tr".($has_bottom_border ? " class=has_bottom_border" : "").">";
        for my $cell (@$row) {
            my ($text, $encode_text) = @_;
            if (ref $cell eq 'HASH') {
                if (defined $cell->{raw_html}) {
                    $text = $cell->{raw_html};
                    $encode_text = 0;
                } else {
                    $text = $cell->{text};
                    $encode_text = 1;
                }
            } else {
                $text = $cell;
                $encode_text = 1;
            }
            $text //= '';
            my $rowspan = int((ref $cell eq 'HASH' ? $cell->{rowspan} : undef) // 1);
            my $colspan = int((ref $cell eq 'HASH' ? $cell->{colspan} : undef) // 1);
            my $align   = ref $cell eq 'HASH' ? $cell->{align} : undef;
            push @table,
                ($in_header ? "<th" : "<td"),
                ($rowspan > 1 ? " rowspan=$rowspan" : ""),
                ($colspan > 1 ? " colspan=$colspan" : ""),
                ($align       ? " align=\"$align\"" : ""),
                ">",
                $encode_text ? _encode($text) : $text,
                $in_header ? "</th>" : "</td>";
	}
        push @table, "</tr>\n";
        if ($i == 0 && $params{header_row}) {
            push @table, "</thead>\n";
        }
    }

    push @table, "</tbody>\n";
    push @table, "</table>\n";

    return join("", grep {$_} @table);
}

# FROM_MODULE: PERLANCAR::List::Util::PP
# BEGIN_BLOCK: max
sub max {
    return undef unless @_; ## no critic: Subroutines::ProhibitExplicitReturnUndef
    my $res = $_[0];
    my $i = 0;
    while (++$i < @_) { $res = $_[$i] if $_[$i] > $res }
    $res;
}
# END_BLOCK: max

# return highest top-index from all rows in case they're different lengths
sub _max_array_index {
    my $rows = shift;
    return max( map { $#$_ } @$rows );
}

1;
#ABSTRACT: Generate HTML table

=for Pod::Coverage ^(max)$

=head1 SYNOPSIS

 use Text::Table::HTML;

 my $rows = [
     # header row
     ['Name', 'Rank', 'Serial'],
     # rows
     ['alice', 'pvt', '123<456>'],
     ['bob',   'cpl', '98765321'],
     ['carol', 'brig gen', '8745'],
 ];
 print Text::Table::HTML::table(rows => $rows, header_row => 1);


=head1 DESCRIPTION

This module provides a single function, C<table>, which formats a
two-dimensional array of data as HTML table.

The example shown in the SYNOPSIS generates the following table:

 <table>
 <thead>
 <tr><th>Name</th><th>Rank</th><th>Serial</th></tr>
 </thead>
 <tbody>
 <tr><td>alice</td><td>pvt</td><td>123&lt;456&gt;</td></tr>
 <tr><td>bob</td><td>cpl</td><td>98765321</td></tr>
 <tr><td>carol</td><td>brig gen</td><td>8745</td></tr>
 </tbody>
 </table>


=head1 FUNCTIONS

=head2 table(%params) => str


=head2 OPTIONS

The C<table> function understands these arguments, which are passed as a hash.

=over

=item * rows (aoaos)

Takes an array reference which should contain one or more rows of data, where
each row is an array reference. And each array element is a string (cell
content) or hashref (with key C<text> to contain the cell text or C<raw_html> to
contain the cell's raw HTML which won't be escaped further), and optionally
other attributes: C<rowspan>, C<colspan>, C<align>, C<bottom_border>).

=item * caption

Optional. Str. If set, will add an HTML C<< <caption> >> element to set the
table caption.

=back


=head1 SEE ALSO

L<Text::Table::HTML::DataTables>

L<Text::Table::Any>

L<Bencher::Scenario::TextTableModules>

=cut
