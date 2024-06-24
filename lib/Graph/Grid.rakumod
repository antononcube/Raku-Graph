use v6.d;

use Graph;

class Graph::Grid is Graph {
    has Int:D $.rows is required;
    has Int:D $.columns is required;

    submethod BUILD(:$!rows!, :$!columns!, :$prefix = '', Str:D :$sep = '_') {
        for ^$!rows -> $r {
            for ^$!columns -> $c {
                my $current = "{$prefix}{$r}_{$c}";
                if $r < $!rows - 1 {
                    self.add-edge($current, "{$prefix}{$r+1}{$sep}{$c}", :!directed);
                }
                if $c < $!columns - 1 {
                    self.add-edge($current, "{$prefix}{$r}{$sep}{$c+1}", :!directed);
                }
            }
        }
    }

    multi method new(Int:D $rows, Int:D $columns, Str:D $prefix = '', Str:D $sep = '_') {
        self.bless(:$rows, :$columns, :$prefix, :$sep);
    }
    multi method new(Int:D :m(:$rows), Int:D :n(:$columns), Str:D :$prefix = '', Str:D :$sep = '_') {
        self.bless(:$rows, :$columns, :$prefix, :$sep);
    }
}

