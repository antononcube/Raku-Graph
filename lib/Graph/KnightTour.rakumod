use v6.d;

use Graph;
use Graph::Utilities;
use Graph::Leaper;


class Graph::KnightTour is Graph::Leaper {
    my @sp-moves = (-2, -1), (-2, 1), (-1, 2), (1, 2);

    multi method new($rows is copy = Whatever, $columns is copy = Whatever, Str:D :$prefix = '', Str:D :$sep = '_', Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(moves => @sp-moves, :$rows, :$columns, :$prefix, :$sep, :$directed);
    }

    multi method new(UInt:D :m(:$rows), UInt:D :n(:$columns), Str:D :$prefix = '', Str:D :$sep = '_', Bool:D :d(:directed-edges(:$directed)) = False) {
        my @moves = [(-2, -1), (-2, 1), (-1, 2), (1, 2)];
        self.bless(moves => @sp-moves, :$rows, :$columns, :$prefix, :$sep, :$directed);
    }
}

