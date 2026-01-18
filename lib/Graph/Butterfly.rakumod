use v6.d;

use Graph;
class Graph::Butterfly is Graph {
    has UInt:D $.n is required;
    has UInt:D $.b = 2;

    submethod BUILD(:$!n, :$!b = 2, Bool:D :$directed = False) {
        my $n = $!n;
        my $b = $!b;

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

                    my $from = "($w0,$i)";
                    my $to   = "($w1," ~ ($i + 1) ~ ")";
                    self.edge-add($from, $to, 1, :$directed);
                }
            }
        }
    }

    multi method new(UInt:D $n, UInt:D $b = 2, Bool:D :d(:$directed) = False) {
        self.bless(:$n, :$b, :$directed);
    }
}