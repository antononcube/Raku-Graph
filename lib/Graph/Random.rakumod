use v6.d;

use Graph;

class Graph::Random is Graph {
    has Int:D $.vertex-count is required;
    has Int:D $.edge-count is required;

    submethod BUILD(:$!vertex-count!, :$!edge-count!, :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        my @all-edges = gather {
            for 1..$!vertex-count -> $i {
                for 1..$!vertex-count -> $j {
                    next if $i == $j;
                    take ("{$prefix}{$i}", "{$prefix}{$j}");
                }
            }
        }
        @all-edges .= pick($!edge-count);
        for @all-edges -> ($from, $to) {
            self.add-edge($from, $to, :$directed);
        }
    }

    multi method new(Int:D $vertex-count, Int:D $edge-count, Str:D $prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:$vertex-count, :$edge-count, :$prefix, :$directed);
    }
    multi method new(Int:D :$vertex-count, Int:D :$edge-count, Str:D :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:$vertex-count, :$edge-count, :$prefix, :$directed);
    }
}

