use v6.d;

use Graph;

class Graph::Random is Graph {
    has Int:D $.vertex-count is required;
    has Int:D $.edge-count is required;

    submethod BUILD(:$!vertex-count!, :$!edge-count!, :$prefix = '') {
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
            self.add-edge($from, $to, :!directed);
        }
    }

    multi method new(Int:D $vertex-count, Int:D $edge-count, Str:D $prefix = '') {
        self.bless(:$vertex-count, :$edge-count, :$prefix);
    }
    multi method new(Int:D :$vertex-count, Int:D :$edge-count, Str:D :$prefix = '') {
        self.bless(:$vertex-count, :$edge-count, :$prefix);
    }
}

