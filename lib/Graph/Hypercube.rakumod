use v6.d;

use Graph;

class Graph::Hypercube is Graph {
    has Int:D $.n is required;

    submethod BUILD(:$!n!, :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        if $directed {
            note 'Directed hypercube graphs are not implemented.';
        }

        my @vertices = ^(2 ** $!n);

        for @vertices -> $v {
            for ^$!n -> $i {
                # Add 2^i to flip the i-th bit
                my $neighbor = $v + (2 ** $i);

                # Ensure within bounds
                $neighbor = $neighbor >= 2 ** $!n ?? $neighbor - 2 ** $!n !! $neighbor;

                # Make vertex binary IDs
                my ($f, $t) = $v.base(2, :$!n), $neighbor.base(2, :$!n);
                $f = '0' x ($!n - $f.chars) ~ $f;
                $t = '0' x ($!n - $t.chars) ~ $t;

                # Add
                if ($f.comb Z[ne] $t.comb).sum == 1 {
                    self.edge-add($f, $t, :!directed);
                }
            }
        }
    }

    multi method new(Int:D $n, Str:D $prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:$n, :$prefix, :$directed);
    }

    multi method new(Int:D :dim(:dimension(:$n)), Str:D :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:$n, :$prefix, :$directed);
    }
}

