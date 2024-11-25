use v6.d;

use Graph;

class Graph::Cycle is Graph {
    has Int:D $.n is required;

    submethod BUILD(:$!n!, :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        for ^$!n -> $i {
            my $next = $i == $!n - 1 ?? 0 !! $i + 1;
            self.edge-add("{$prefix}{$i}", "{$prefix}{$next}", :$directed);
        }
        self.vertex-coordinates =
                self.vertex-list.map({ my $i = $_.subst($prefix).Int - 1; $_ => [cos(2 * pi / $!n * $i), sin(2 * pi / $!n * $i)]}).Hash;
    }

    multi method new(Int:D $n, Str:D :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:$n, :$prefix, :$directed);
    }

    multi method new(Int:D :$n, Str:D :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:$n, :$prefix, :$directed);
    }
}

