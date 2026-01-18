use v6.d;

use Graph;
class Graph::Butterfly is Graph {
    has UInt:D $.n is required;
    has UInt:D $.base = 2;

    submethod BUILD(:$!n, :$!base = 2, Bool:D :d(:directed-edges(:$directed)) = False) {
        my $n = $!n;
        my $b = $!base;

        my $bn = $b ** $n;
        my @w = (^$bn).map({
            .base($b).fmt('%0' ~ $n ~ 's')
        });

        for ^$n -> $i {
            for @w -> $w0 {
                my @digits = $w0.comb;
                for ^$b -> $d {
                    my @d1 = @digits;
                    @d1[$i] = $d.Str;
                    my $w1 = @d1.join;

                    my $from = "{$w0}_{$i}";
                    my $to   = "{$w1}_{$i + 1}";
                    self.edge-add($from, $to, 1, :$directed);
                }
            }
        }

        self.vertex-coordinates =
                self.vertex-list.map({ $_ => $_.split('_', :skip-empty).cache.&{ [$_.head.parse-base($b), $_.tail.Int] } }).Hash;
    }

    multi method new(UInt:D $n, UInt:D :b(:$base) = 2, Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:$n, :$base, :$directed);
    }
    multi method new(UInt:D $n, UInt:D $base = 2, Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:$n, :$base, :$directed);
    }
}