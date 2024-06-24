use v6.d;

use Graph;

class Graph::Wheel is Graph {
    has Int:D $.n is required;
    has Str:D $.center = 'center';

    submethod BUILD(:$!n!, :$!center = '0', :$prefix = '') {
        for 1..$!n -> $i {
            self.add-edge($!center, "{$prefix}{$i}", :!directed);
            my $next = $i == $!n ?? 1 !! $i + 1;
            self.add-edge("{$prefix}{$i}", "{$prefix}{$next}", :!directed);
        }
    }

    multi method new(Int:D $n, Str:D $center = 'center', Str:D $prefix = '') {
        self.bless(:$n, :$center, :$prefix);
    }
    multi method new(Int:D :spokes(:$n), Str:D :$center = 'center', Str:D :$prefix = '') {
        self.bless(:$n, :$center, :$prefix);
    }
}

