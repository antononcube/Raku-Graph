use v6.d;

use Graph;

class Graph::Cycle is Graph {
    has Int:D $.n is required;

    submethod BUILD(:$!n!, :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        for 1..$!n -> $i {
            my $next = $i == $!n ?? 1 !! $i + 1;
            self.add-edge("{$prefix}{$i}", "{$prefix}{$next}", :$directed);
        }
    }

    multi method new(Int:D $n, Str:D $prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:$n, :$prefix, :$directed);
    }

    multi method new(Int:D :$n, Str:D :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:$n, :$prefix, :$directed);
    }
}

