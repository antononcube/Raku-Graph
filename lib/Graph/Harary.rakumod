use v6.d;

use Graph;

class Graph::Harary is Graph {
    has Int:D $.k is required;
    has Int:D $.n is required;

    submethod BUILD(:$!k!, :$!n!, Str:D :$prefix = '') {

        for ^$!n -> $i {
            for (1 ... $!k div 2) -> $j {
                self.edge-add($prefix ~ $i.Str, $prefix ~ (($i + $j) % $!n).Str, :!directed);
                self.edge-add($prefix ~ $i.Str, $prefix ~ (($i - $j) % $!n).Str, :!directed);
            }
        }

        if $!k !%% 2 {
            if $!n %% 2 {
                for ^($!n div 2) -> $i {
                    self.edge-add($prefix ~ $i.Str, $prefix ~ ($i + $!n div 2).Str, :!directed);
                }
            } else {
                for ^(($!n - 1) div 2) -> $i {
                    self.edge-add($prefix ~ $i.Str, $prefix ~ ($i + ($!n + 1) div 2).Str, :!directed);
                }
                self.edge-add($prefix ~ '0', $prefix ~ (($!n - 1) div 2).Str, :!directed);
                self.edge-add($prefix ~ '0', $prefix ~ (($!n + 1) div 2).Str, :!directed)
            }
        }

        # Same as Circulant
        self.vertex-coordinates =
                self.vertex-list.map({ my $i = $_.subst($prefix).Int - 1; $_ => [cos(2 * pi / $!n * $i), sin(2 * pi / $!n * $i)]}).Hash;
    }

    multi method new(Int:D $k, Int:D $n, Str:D :$prefix = '') {
        self.bless(:$k, :$n, :$prefix);
    }

    multi method new(Int:D :$n, Int:D :$k, Str:D :$prefix = '') {
        self.new($k, $n, :$prefix);
    }
}

