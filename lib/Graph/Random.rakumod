use v6.d;

use Graph;
use Graph::Distribution;

class Graph::Random is Graph {
    has $.dist is required;

    submethod BUILD(:$!dist, :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        given $!dist {
            when ($_ ~~ Graph::Distribution::Bernoulli:D) || ($_ ~~ Graph::Distribution::Uniform:D) {
                my @all-edges = gather {
                    for 1 .. $!dist.vertex-count -> $i {
                        for 1 .. $!dist.vertex-count -> $j {
                            next if $i == $j;
                            take ("{ $prefix }{ $i }", "{ $prefix }{ $j }");
                        }
                    }
                }

                @all-edges =
                        do if $_ ~~ (Graph::Distribution::Bernoulli:D) {
                            # Divide by the probability by two since
                            # we use the Cartesian product of vertexes.
                            @all-edges.grep({ rand ≤ $!dist.p / 2});
                        } else {
                            @all-edges.pick($!dist.edges-count);
                        }

                for @all-edges -> ($from, $to) {
                    self.add-edge($from, $to, :$directed);
                }
            }

            when Graph::Distribution::Price:D {
                self!generate-de-solla-price-graph($!dist.vertex-count, $!dist.edges-count, $!dist.attractiveness, :$prefix);
            }

            default {
                die "Uknown or un-implemented graph distribution.";
            }
        }
    }

    #------------------------------------------------------
    # For PriceGraphDistribution
    method !generate-de-solla-price-graph(Int:D $n, Int:D $k, Numeric:D $a, Str:D :$prefix = '') {
        my @vertexes = ["{$prefix}0", ];

        for 1..$n-1 -> $i {
            my $new-vertex = $prefix ~ ($k + $i - 1);
            my @degrees = @vertexes.elems ==1 ?? [1,] !! @vertexes.map: { self.vertex-in-degree($_) };
            #my $total-degree = @degrees.sum + $a * @vertexes.elems;
            #my @probabilities = @degrees.map: { ($_ + $a) / $total-degree };
            my @freqs = @degrees.map: { ($_ + $a) };

            #my $vertexMix = (@vertexes Z=> @probabilities).MixHash;3
            my $vertexBag = (@vertexes Z=> @freqs).BagHash;

            #$vertexMix.roll($k).map({ self.add-edge($new-vertex, $_, 1, :directed) });
            $vertexBag.pick($k).map({ self.add-edge($new-vertex, $_, 1, :directed) });

            @vertexes.push: $new-vertex;
        }
    }

    #------------------------------------------------------
    multi method new(Int:D $vertex-count, Int:D $edges-count, Str:D $prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        my $dist = Graph::Distribution::Uniform.new(:$vertex-count, :$edges-count);
        self.bless(:$dist, :$prefix, :$directed);
    }

    multi method new(Int:D :v(:$vertex-count), Int:D :n(:$edges-count), Str:D :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        my $dist = Graph::Distribution::Uniform.new(:$vertex-count, :$edges-count);
        self.bless(:$dist, :$prefix, :$directed);
    }

    #------------------------------------------------------
    multi method new($dist, Str:D :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:$dist, :$prefix, :$directed);
    }
}