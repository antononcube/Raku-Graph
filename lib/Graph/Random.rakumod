use v6.d;

use Graph;

class Graph::Random is Graph {
    has Int:D $.number-of-vertexes is required;
    has Int:D $.number-of-edges is required;

    submethod BUILD(:$!number-of-vertexes!, :$!number-of-edges!, :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        my @all-edges = gather {
            for 1..$!number-of-vertexes -> $i {
                for 1..$!number-of-vertexes -> $j {
                    next if $i == $j;
                    take ("{$prefix}{$i}", "{$prefix}{$j}");
                }
            }
        }
        @all-edges .= pick($!number-of-edges);
        for @all-edges -> ($from, $to) {
            self.add-edge($from, $to, :$directed);
        }
    }

    multi method new(Int:D $number-of-vertexes, Int:D $number-of-edges, Str:D $prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:$number-of-vertexes, :$number-of-edges, :$prefix, :$directed);
    }
    multi method new(Int:D :v(:$number-of-vertexes), Int:D :n(:$number-of-edges), Str:D :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:$number-of-vertexes, :$number-of-edges, :$prefix, :$directed);
    }
}