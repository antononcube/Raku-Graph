use v6.d;

use Graph;

class Graph::Grid is Graph {
    has Int:D $.rows is required;
    has Int:D $.columns is required;

    submethod BUILD(:$!rows!, :$!columns!, :$prefix = '') {
        for 1..$!rows -> $r {
            for 1..$!columns -> $c {
                my $current = "{$prefix}{$r}_{$c}";
                if $r < $!rows {
                    self.add-edge($current, "{$prefix}{$r+1}_{$c}", :!directed);
                }
                if $c < $!columns {
                    self.add-edge($current, "{$prefix}{$r}_{$c+1}", :!directed);
                }
            }
        }
    }

    multi method new(Int:D $rows, Int:D $columns, Str:D $prefix = '') {
        self.bless(:$rows, :$columns, :$prefix);
    }
    multi method new(Int:D :$rows, Int:D :$columns, Str:D :$prefix = '') {
        self.bless(:$rows, :$columns, :$prefix);
    }
}

