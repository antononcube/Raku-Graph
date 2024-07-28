use v6.d;

use Graph;

class Graph::Star is Graph {
    has Int:D $.n is required;
    has Str:D $.center = '0';

    submethod BUILD(:$!n!, :$center is copy = Whatever, :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        if $center.isa(Whatever) { $center = "{$prefix}0" }
        die 'The parameter $center is expected to be a string or Whatever'
        unless $center ~~ Str:D;

        $!center = $center;
        for 1..$!n -> $i {
            self.add-edge($!center, "$prefix$i", :$directed);
        }
    }

    multi method new(Int:D $n, $center = Whatever, Str:D $prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:$n, :$center, :$prefix, :$directed);
    }

    multi method new(Int:D $n, $center = Whatever, Str:D :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:$n, :$center, :$prefix, :$directed);
    }

    multi method new(Int:D :leaves(:rays(:$n)), :$center = Whatever, Str:D :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:$n, :$center, :$prefix, :$directed);
    }
}

