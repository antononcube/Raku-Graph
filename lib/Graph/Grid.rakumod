use v6.d;

use Graph;

class Graph::Grid is Graph {
    has Int:D $.rows is required;
    has Int:D $.columns is required;

    submethod BUILD(:$!rows!, :$!columns!, :$prefix = '', Str:D :$sep = '_', Bool:D :d(:directed-edges(:$directed)) = False) {
        for ^$!rows -> $r {
            for ^$!columns -> $c {
                my $current = "{$prefix}{$r}_{$c}";
                if $r < $!rows - 1 {
                    self.edge-add($current, "{$prefix}{$r+1}{$sep}{$c}", :$directed);
                }
                if $c < $!columns - 1 {
                    self.edge-add($current, "{$prefix}{$r}{$sep}{$c+1}", :$directed);
                }
            }
        }

        self.vertex-coordinates = self.vertex-list.map({ $_ => $_.subst($prefix).split($sep)».Int.reverse.List }).Hash;
    }

    multi method new(Int:D $rows, Int:D $columns, Str:D :$prefix = '', Str:D :$sep = '_', Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:$rows, :$columns, :$prefix, :$sep, :$directed);
    }
    multi method new(Int:D :m(:$rows), Int:D :n(:$columns), Str:D :$prefix = '', Str:D :$sep = '_', Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:$rows, :$columns, :$prefix, :$sep, :$directed);
    }
}

