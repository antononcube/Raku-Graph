use v6.d;

use Graph;

class Graph::KnightTour is Graph {
    has Int:D $.rows is required;
    has Int:D $.columns is required;

    submethod BUILD(:$!rows!, :$!columns!, Str:D :$prefix = '', Str:D :$sep = '_') {
        my @moves = (-2, -1, 1, 2).combinations(2).grep({ $_[0].abs != $_[1].abs });
        for ^$!rows -> $row {
            for ^$!columns -> $col {
                for @moves -> $move {
                    my ($dr, $dc) = $move;
                    my $new-row = $row + $dr;
                    my $new-col = $col + $dc;
                    if $new-row >= 0 && $new-row < $!rows && $new-col >= 0 && $new-col < $!columns {
                        self.add-edge("{$prefix}{$row}{$sep}{$col}", "{$prefix}{$new-row}{$sep}{$new-col}");
                    }
                }
            }
        }
    }

    multi method new(Int:D $rows, Int:D $columns, Str:D $prefix = '', Str:D $sep = '_') {
        self.bless(:$rows, :$columns, :$prefix, :$sep);
    }
    multi method new(Int:D :m(:$rows), Int:D :n(:$columns), Str:D :$prefix = '', Str:D :$sep = '_') {
        self.bless(:$rows, :$columns, :$prefix, :$sep);
    }
}

