use v6.d;

use Graph;

class Graph::Star is Graph {
    has Int:D $.n is required;
    has Str:D $.center = '0';

    submethod BUILD(:$!n!, :$!center = '0', :$prefix = '') {
        for 1..$!n -> $i {
            self.add-edge($!center, "$prefix$i");
        }
    }

    multi method new(Int:D $n, Str:D $center = 'center', Str:D $prefix = '') {
        self.bless(:$n, :$center, :$prefix);
    }
    multi method new(Int:D :leaves(:rays(:$n)), Str:D :$center = 'center', Str:D :$prefix = '') {
        self.bless(:$n, :$center, :$prefix);
    }
}

