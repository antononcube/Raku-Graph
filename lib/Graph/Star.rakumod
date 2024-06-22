use v6.d;

use Graph;

class Graph::Star is Graph {
    has Int:D $.leaves is required;
    has Str:D $.center = '0';

    submethod BUILD(:$!leaves!, :$!center = '0', :$prefix = '') {
        for 1..$!leaves -> $i {
            self.add-edge($!center, "$prefix$i");
        }
    }

    multi method new(Int:D $leaves, Str:D $center = 'center', Str:D $prefix = '') {
        self.bless(:$leaves, :$center, :$prefix);
    }
    multi method new(Int:D :$leaves, Str:D :$center = 'center', Str:D :$prefix = '') {
        self.bless(:$leaves, :$center, :$prefix);
    }
}

