use v6.d;

use Graph;
use Graph::Distributions;

class Graph::Random is Graph {
    has $.dist is required;

    submethod BUILD(:$!dist, :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        given $!dist {
            when ($_ ~~ BernoulliGraphDistribution:D) || ($_ ~~ UniformGraphDistribution:D) {
                my @all-edges = gather {
                    for 1 .. $!dist.vertex-count -> $i {
                        for 1 .. $!dist.vertex-count -> $j {
                            next if $i == $j;
                            take ("{ $prefix }{ $i }", "{ $prefix }{ $j }");
                        }
                    }
                }

                @all-edges =
                        do if $_ ~~ (BernoulliGraphDistribution:D) {
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

            default {
                die "Uknown or un-implemented graph distribution.";
            }
        }
    }

    #------------------------------------------------------
    multi method new(Int:D $vertex-count, Int:D $edges-count, Str:D $prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        my $dist = UniformGraphDistribution.new(:$vertex-count, :$edges-count);
        self.bless(:$dist, :$prefix, :$directed);
    }

    multi method new(Int:D :v(:$vertex-count), Int:D :n(:$edges-count), Str:D :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        my $dist = UniformGraphDistribution.new(:$vertex-count, :$edges-count);
        self.bless(:$dist, :$prefix, :$directed);
    }

    #------------------------------------------------------
    multi method new($dist, Str:D :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:$dist, :$prefix, :$directed);
    }
}