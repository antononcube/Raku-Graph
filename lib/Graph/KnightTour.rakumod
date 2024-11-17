use v6.d;

use Graph;
use Graph::Utilities;

class Graph::KnightTour is Graph {
    has Int:D $.rows is required;
    has Int:D $.columns is required;

    submethod BUILD(:$!rows!, :$!columns!, Str:D :$prefix = '', Str:D :$sep = '_', Bool:D :d(:directed-edges(:$directed)) = False) {
        if $directed {
            note 'Directed knight-tour graphs are not implemented.';
        }

        my @moves = (-2, -1, 1, 2).combinations(2).grep({ $_[0].abs != $_[1].abs });
        for ^$!rows -> $row {
            for ^$!columns -> $col {

                # In order to prevent "skipped" cells we add empty vertex adjacency list.
                # See for example 3x3 graph here: https://mathworld.wolfram.com/KnightGraph.html
                self.adjacency-list{"{$prefix}{$col}{$sep}{$row}"} = {};

                for @moves -> $move {
                    my ($dr, $dc) = $move;
                    my $new-row = $row + $dr;
                    my $new-col = $col + $dc;
                    if $new-row >= 0 && $new-row < $!rows && $new-col >= 0 && $new-col < $!columns {
                        # Note the columns are the X-coordinates and the rows are the Y-coordinates.
                        self.add-edge("{$prefix}{$col}{$sep}{$row}", "{$prefix}{$new-col}{$sep}{$new-row}", :!directed);
                    }
                }
            }
        }

        self.vertex-coordinates = self.vertex-list.map({ $_ => $_.subst($prefix).split($sep)».Int.List }).Hash;
    }

    multi method new($rows is copy = Whatever, $columns is copy = Whatever, Str:D :$prefix = '', Str:D :$sep = '_', Bool:D :d(:directed-edges(:$directed)) = False) {

        ($rows, $columns) = Graph::Utilities::ProcessPairedUIntArgs($rows, $columns, 8);
        die 'The first argument is expected to be a positive integer or Whatever.'
        unless $rows ~~ Int:D && $rows > 0;

        die 'The second argument is expected to be a positive integer or Whatever.'
        unless $columns ~~ Int:D && $columns > 0;

        self.bless(:$rows, :$columns, :$prefix, :$sep, :$directed);
    }

    multi method new(UInt:D :m(:$rows), UInt:D :n(:$columns), Str:D :$prefix = '', Str:D :$sep = '_', Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:$rows, :$columns, :$prefix, :$sep, :$directed);
    }
}

