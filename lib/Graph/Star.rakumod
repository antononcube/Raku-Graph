use v6.d;

use Graph;

class Graph::Star is Graph {
    has Int:D $.n is required;
    has Str:D $.center = '0';

    submethod BUILD(:$!n!, :$!center = '0', :$prefix = '', Bool:D :$directed = False) {
        for 1..$!n -> $i {
            self.add-edge($!center, "$prefix$i", :$directed);
        }
    }

    multi method new(Int:D $n, Str:D $center = 'center', Str:D $prefix = '', Bool:D :$directed = False) {
        self.bless(:$n, :$center, :$prefix, :$directed);
    }
    multi method new(Int:D :leaves(:rays(:$n)), Str:D :$center = 'center', Str:D :$prefix = '', Bool:D :$directed = False) {
        self.bless(:$n, :$center, :$prefix, :$directed);
    }
}

