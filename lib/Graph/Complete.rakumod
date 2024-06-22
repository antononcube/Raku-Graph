use v6.d;

use Graph;

class Graph::Complete is Graph {
    has Int:D $.n is required;

    submethod BUILD(:$!n!, :$prefix = '') {
        for 1..$!n -> $i {
            for 1..$!n -> $j {
                next if $i == $j;
                self.add-edge("$prefix$i", "$prefix$j", :!directed);
            }
        }
    }

    multi method new(Int:D $n, Str:D $prefix = '') {
        self.bless(:$n, :$prefix);
    }

    multi method new(Int:D :$n, Str:D :$prefix = '') {
        self.bless(:$n, :$prefix);
    }
}

