use v6.d;

use Graph;

class Graph::Complete is Graph {
    has Int:D $.n is required;

    submethod BUILD(:$!n!, :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        for 1..$!n -> $i {
            for 1..$!n -> $j {
                next if $i == $j;
                self.edge-add("$prefix$i", "$prefix$j", :$directed);
                if $directed {
                    self.edge-add("$prefix$j", "$prefix$i", :$directed);
                }
            }
        }
    }

    multi method new(Int:D $n, Str:D $prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:$n, :$prefix, :$directed);
    }

    multi method new(Int:D $n, Str:D :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:$n, :$prefix, :$directed);
    }

    multi method new(Int:D :$n, Str:D :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:$n, :$prefix, :$directed);
    }
}

