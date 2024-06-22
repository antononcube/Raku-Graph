use v6.d;

use Graph;

class Graph::Cycle is Graph {
    has Int:D $.n is required;

    submethod BUILD(:$!n!, :$prefix = '') {
        for 1..$!n -> $i {
            my $next = $i == $!n ?? 1 !! $i + 1;
            self.add-edge("{$prefix}{$i}", "{$prefix}{$next}", :!directed);
        }
    }

    multi method new(Int:D $n, Str:D $prefix = '') {
        self.bless(:$n, :$prefix);
    }

    multi method new(Int:D :$n, Str:D :$prefix = '') {
        self.bless(:$n, :$prefix);
    }
}

