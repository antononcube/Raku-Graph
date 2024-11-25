use v6.d;

use Graph;

class Graph::Wheel is Graph {
    has Int:D $.n is required;
    has Str:D $.center = '0';

    submethod BUILD(:$!n!, :$center is copy = Whatever, :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        if $center.isa(Whatever) { $center = "{$prefix}0" }

        $!center = $center;
        for 1..$!n -> $i {
            self.edge-add($!center, "{$prefix}{$i}", :$directed);
            my $next = $i == $!n ?? 1 !! $i + 1;
            self.edge-add("{$prefix}{$i}", "{$prefix}{$next}", :$directed);
        }

        self.vertex-coordinates =
                self.vertex-list.grep({ $_ ne $center }).map({ my $i = $_.subst($prefix).Int - 1; $_ => [cos(2 * pi / $!n * $i), sin(2 * pi / $!n * $i)]}).Hash;
        self.vertex-coordinates{$!center} = [0, 0];
    }

    multi method new(Int:D $n, $center = Whatever, Str:D $prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:$n, :$center, :$prefix, :$directed);
    }

    multi method new(Int:D $n, :$center = Whatever, Str:D :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:$n, :$center, :$prefix, :$directed);
    }

    multi method new(Int:D :spokes(:$n), :$center = Whatever, Str:D :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:$n, :$center, :$prefix, :$directed);
    }
}

