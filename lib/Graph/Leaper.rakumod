use v6.d;

use Graph;
use Graph::Utilities;

class Graph::Leaper is Graph {
    has @.moves is required;
    has Int:D $.rows is required;
    has Int:D $.columns is required;

    sub check-moves($moves) {
        $moves ~~ (Array:D | List:D | Seq:D) &&
                $moves.all ~~ (Array:D | List:D | Seq:D) &&
                $moves».elems.all == 2 &&
                $moves.flat(:hammer).all ~~ Int:D
    }

    submethod BUILD(:@!moves, :$!rows!, :$!columns!, Str:D :$prefix = '', Str:D :$sep = '_', Bool:D :d(:directed-edges(:$directed)) = False) {
        if $directed {
            note 'Directed knight-tour graphs are not implemented.';
        }

        for ^$!rows -> $row {
            for ^$!columns -> $col {

                # In order to prevent "skipped" cells we add empty vertex adjacency list.
                # See for example 3x3 graph here: https://mathworld.wolfram.com/KnightGraph.html
                self.adjacency-list{"{$prefix}{$col}{$sep}{$row}"} = {};

                for @!moves -> $move {
                    my ($dr, $dc) = $move;
                    my $new-row = $row + $dr;
                    my $new-col = $col + $dc;
                    if $new-row >= 0 && $new-row < $!rows && $new-col >= 0 && $new-col < $!columns {
                        # Note the columns are the X-coordinates and the rows are the Y-coordinates.
                        self.edge-add("{$prefix}{$col}{$sep}{$row}", "{$prefix}{$new-col}{$sep}{$new-row}", :!directed);
                    }
                }
            }
        }

        self.vertex-coordinates = self.vertex-list.map({ $_ => $_.subst($prefix).split($sep)».Int.List }).Hash;
    }

    multi method new(
            $moves! is copy,
            $rows! is copy,
            $columns! is copy,
            Str:D :$prefix = '',
            Str:D :$sep = '_',
            Bool:D :d(:directed-edges(:$directed)) = False
                     ) {

        if $moves.isa(Whatever) {
            $moves = [(-2, -1), (-2, 1), (-1, 2), (1, 2)]
        } elsif $moves ~~ (Array:D | List:D | Seq:D) && $moves.elems == 2 && $moves.all ~~ Int:D && $moves.all ≥ 0 {
            $moves = (-$moves.head, -$moves.tail, $moves.tail, $moves.head).sort.combinations(2).grep({ $_».abs.sum == $moves.sum }).unique.Array
        }

        die 'The first argument is expected to be a list of two non-negative integers, a list of length-two lists of non-negative integers, or Whatever'
        unless check-moves($moves);

        ($rows, $columns) = Graph::Utilities::ProcessPairedUIntArgs($rows, $columns, 8);
        die 'The second argument is expected to be a positive integer or Whatever.'
        unless $rows ~~ Int:D && $rows > 0;

        die 'The third argument is expected to be a positive integer or Whatever.'
        unless $columns ~~ Int:D && $columns > 0;

        self.bless(:$moves, :$rows, :$columns, :$prefix, :$sep, :$directed);
    }

    multi method new(:$moves!, UInt:D :m(:$rows), UInt:D :n(:$columns), Str:D :$prefix = '', Str:D :$sep = '_', Bool:D :d(:directed-edges(:$directed)) = False) {

        die 'The argument $moves is expected to be a list of length-two lists of integers.'
        unless check-moves($moves);

        self.bless(:$moves, :$rows, :$columns, :$prefix, :$sep, :$directed);
    }
}

