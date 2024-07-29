use v6.d;

use Graph;

class Graph::Petersen is Graph {
    submethod BUILD(:$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        my @edges = [0, 2], [0, 3], [0, 5], [1, 3], [1, 4], [1, 6],
                    [2, 4], [2, 7],
                    [3, 8], [4, 9], [5, 6], [5, 9], [6, 7], [7, 8], [8, 9];
        for @edges -> @r {
            self.add-edge($prefix ~ @r[0], $prefix ~ @r[1], :!directed);
            if $directed {
                self.add-edge($prefix ~ @r[1], $prefix ~ @r[0], :!directed);
            }
        }

        self.vertex-coordinates =
                [|(5..9).pairs.map({ "{$prefix}{$_.value}" => [cos(pi / 2 + 2 * pi / 5 * $_.key), sin(pi / 2 + 2 * pi / 5 * $_.key)] >>*>> 2}),
                 |(^5).pairs.map({ "{$prefix}{$_.value}" => [cos(pi / 2 + 2 * pi / 5 * $_.key), sin(pi / 2 + 2 * pi / 5 * $_.key)]})];
        self.vertex-coordinates .= Hash;
    }

    multi method new(Str:D :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:$prefix, :$directed);
    }
}

