use v6.d;

use Graph;

class Graph::CompleteKaryTree is Graph {
    has Int:D $.n is required;
    has Int:D $.k is required;

    submethod BUILD(:$!n!, :$!k!, :$prefix = '', Bool:D :$directed = False) {
        my $m = $!k ≥ 2 ?? ($!k ** $!n - 1) / ($!k - 1) !! $!n;
        my @nodes = ^$m;
        for @nodes -> $parent {
            for 1..$!k -> $i {
                my $child = $parent * $!k + $i;
                last if $child > @nodes.elems - 1;
                self.add-edge($prefix ~ $parent.Str, $prefix ~ $child.Str, :$directed);
            }
        }
    }

    multi method new(Int:D $n, Int:D $k = 2, Str:D $prefix = '', Bool:D :$directed = False) {
        self.bless(:$n, :$k, :$prefix, :$directed);
    }

    multi method new(Int:D :$n, Int:D :$k = 2, Str:D :$prefix = '', Bool:D :$directed = False) {
        self.bless(:$n, :$k, :$prefix, :$directed);
    }
}

