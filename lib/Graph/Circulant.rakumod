use v6.d;

use Graph;

class Graph::Circulant is Graph {
    has Int:D $.n is required;
    has Int:D @.jumps is required;

    submethod BUILD(:$!n!, :@!jumps!, Str:D :$prefix = '') {
        for ^$!n -> $i {
            for @!jumps -> $j {
                self.edge-add($prefix ~ $i.Str, $prefix ~ (($i + $j) % $!n).Str, :!directed);
                self.edge-add($prefix ~ $i.Str, $prefix ~ (($i - $j) % $!n).Str, :!directed);
            }
        }
        self.vertex-coordinates =
                self.vertex-list.map({ my $i = $_.subst($prefix).Int - 1; $_ => [cos(2 * pi / $!n * $i), sin(2 * pi / $!n * $i)]}).Hash;
    }

    multi method new(Int:D $n, Int:D $jump, Str:D :$prefix = '') {
        self.bless(:$n, jumps => [$jump,], :$prefix);
    }

    multi method new(Int:D $n, @jumps, Str:D :$prefix = '') {
        self.bless(:$n, :@jumps, :$prefix);
    }

    multi method new(Int:D :$n, :j(:jump(:$jumps)), Str:D :$prefix = '') {
        self.new($n, $jumps, :$prefix);
    }
}

