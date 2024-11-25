use v6.d;

use Graph;

class Graph::Circulant is Graph {
    has Int:D $.n is required;
    has Int:D $.jump is required;

    submethod BUILD(:$!n!, :$!jump!, Str:D :$prefix = '') {
        for ^$!n -> $i {
            self.edge-add($prefix ~ $i.Str, $prefix ~ (($i + $!jump) % $!n).Str, :!directed);
            self.edge-add($prefix ~ $i.Str, $prefix ~ (($i - $!jump) % $!n).Str, :!directed);
        }
    }

    multi method new(Int:D $n, Int:D $jump, Str:D :$prefix = '') {
        self.bless(:$n, :$jump, :$prefix);
    }

    multi method new(Int:D :$n, Int:D :j(:$jump), Str:D :$prefix = '') {
        self.bless(:$n, :$jump, :$prefix);
    }
}

