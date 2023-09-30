package Text::Table::HTML;

use 5.010001;
use strict;
use warnings;

# AUTHORITY
# DATE
# DIST
# VERSION

sub _croak {
    require Carp;
    goto &Carp::croak;
}

sub _encode {
    state $load = do { require HTML::Entities };
    HTML::Entities::encode_entities(shift);
}

sub table {
    my %params = @_;
    my $rows = $params{rows} or die "Must provide rows!";

    # here we go...
    my @table;

    my $attr =defined $params{attr}
      ?  join q{ }, '', map { qq{$_="$params{attr}{$_}"} } keys %{$params{attr}}
      : '';

    push @table, "<table$attr>\n";

    if (defined $params{caption}) {
        push @table, "<caption>"._encode($params{caption})."</caption>\n";
    }

    if ( defined $params{colgroup} ) {
        push @table, "<colgroup>\n";

        for my $col ( @{ $params{colgroup} } ) {

            my @tag = '<col';
            if ( defined $col ) {
                if ( 'HASH' eq ref $col ) {
                    push @tag, qq{$_="$col->{$_}"} for keys %{$col};
                }
                else {
                    push @tag, $col;
                }
            }
            push @tag, '/>';
            push @table, join( q{ }, @tag ), "\n";
        }

        push @table, "</colgroup>\n";
    }

    # then the data
    my $header_row   = $params{header_row} // 0;
    my $needs_thead = !!$header_row;
    my $needs_tbody = !!1;
    foreach my $row ( @{$rows} ) {

        my $coltag = 'td';

        if ($header_row ) {
            $coltag = 'th';

            if ($needs_thead) {
                push @table, "<thead>\n";
                $needs_thead = !!0;
            }
        }

        elsif ($needs_tbody) {
            push @table, "<tbody>\n";
            $needs_tbody = !!0;
        }

        my $bottom_border;

        my @row;

        for my $cell (@$row) {

            my $celltag = $coltag;
            my $text;
            my $attr = '';

            if (ref $cell eq 'HASH') {

                # add a class attribute for bottom_border if
                # any cell in the row has it set. once the attribute is set,
                # no need to do the check again.
                $bottom_border //=
                  ($cell->{bottom_border} || undef) && " class=has_bottom_border";

                if (defined $cell->{raw_html}) {
                    $text = $cell->{raw_html};
                } else {
                    $text = _encode( $cell->{text} // '' );
                }

                my $rowspan = int($cell->{rowspan}  // 1);
                $attr .= " rowspan=$rowspan" if $rowspan > 1;

                my $colspan = int($cell->{colspan}  // 1);
                $attr .= " colspan=$colspan" if $colspan > 1;

                $attr .= ' align="' . $cell->{align} . '"' if defined $cell->{align};


                $celltag = $cell->{tag} if defined $cell->{tag};

                if ( defined $cell->{scope} ) {
                    _croak( "'scope' attribute is only valid in header cells" )
                      unless $coltag eq 'th';
                    $attr .= ' scope="' . $cell->{scope} . '"'
                }
                $attr .= ' style="' . $cell->{style} . '"' if defined $cell->{style};
            }
            else {
                $text = _encode( $cell // '' );
            }

            push @row,
              '<' . $celltag . $attr . '>', $text, '</' . $celltag . '>';
	}

        push @table,
          "<tr". ( $bottom_border // '' ) .">",
          @row,
          "</tr>\n";

        if ( $header_row && $header_row-- == 1 ) {
            push @table, "</thead>\n";
        }
    }

    push @table, "<tbody>\n" if $needs_tbody;
    push @table, "</tbody>\n";
    push @table, "</table>\n";

    return join("", grep {$_} @table);
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
two-dimensional array of data as HTML table. Its interface was first modelled
after L<Text::Table::Tiny> 0.03.

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

=item * rows

Required. Array of array of (scalars or hashrefs). One or more rows of data,
where each row is an array reference. And each array element is a string (cell
content) or hashref (with key C<text> to contain the cell text or C<raw_html> to
contain the cell's raw HTML which won't be escaped further), and optionally
other attributes: C<rowspan>, C<colspan>, C<align>, C<style>, C<scope>, C<bottom_border>, C<tag>).

The C<tag> attribute specifies the tag to use for that cell.  For example,

  header_row => 1,
  rows =>
    [ [ '&nbsp', 'January', 'December' ],
      [ { tag => 'th', text => 'Boots' } , 20, 30 ],
      [ { tag => 'th', text => 'Frocks' } , 40, 50 ],
    ]

generates a table where each element in the first row is a header
element, and the first element in subsequent rows is an element.

=item * caption

Optional. Str. If set, will add an HTML C<< <caption> >> element to set the
table caption.

=item * header_row

Optional. Integer. Default 0. Whether we should add header row(s) (rows inside
C<< <thead> >> instead of C<< <tbody> >>). Support multiple header rows; you can
set this argument to an integer larger than 1.

=item * attr

Optional. Hash.  The hash elements are added as attributes to the C<table> tag.

=item * colgroup

Optional. An array of scalars or hashes which define a C<colgroup> block.

The array should contain one entry per column or per span of
columns. If an entry is C<undef>, or an empty hash, then an empty C<col>
tag will be added.

Hashes are translated into tag attributes; scalars are put into the C<col>
tag as is.  For example,

  colgroup => [ undef, {}, q{span="2"}, { class => 'batman' } ]

results in

  <colgroup>
  <col/>
  <col/>
  <col span="2" />
  <col class="batman" />
  </colgroup>

=back


=head1 COMPATIBILITY NOTES WITH TEXT::TABLE::TINY

In C<Text::Table::HTML>, C<header_row> is an integer instead of boolean. It
supports multiple header rows.

Cells in C<rows> can be hashrefs instead of scalars.


=head1 SEE ALSO

L<Text::Table::HTML::DataTables>

L<Text::Table::Any>

L<Bencher::Scenario::TextTableModules>

=cut
