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
                        for ($directed ?? 1 !! $i + 1) .. $!dist.vertex-count -> $j {
                            next if $i == $j;
                            take ("{ $prefix }{ $i }", "{ $prefix }{ $j }");
                        }
                    }
                }

                @all-edges =
                        do if $_ ~~ (Graph::Distribution::Bernoulli:D) {
                            @all-edges.grep({ rand ≤ $!dist.p });
                        } else {
                            @all-edges.pick($!dist.edges-count);
                        }

                for @all-edges -> ($from, $to) {
                    self.add-edge($from, $to, :$directed);
                }

                # Find the vertices without edges
                my @singleVertexes = (1 .. $!dist.vertex-count).map({ $prefix ~ $_ });
                @singleVertexes = (@singleVertexes (-) self.vertex-list).keys;

                # Add the single vertices
                for @singleVertexes -> $v {
                    self.adjacency-list.push($v => %());
                }
            }

            when Graph::Distribution::BarabasiAlbert:D {
                self!generate-barabasi-albert-graph($!dist.vertex-count, $!dist.edges-count, :$prefix);
            }

            when Graph::Distribution::Spatial:D {
                self!generate-spatial-graph($!dist.vertex-count, $!dist.radius, $!dist.dimension, :$prefix);
            }

            when Graph::Distribution::Price:D {
                self!generate-de-solla-price-graph($!dist.vertex-count, $!dist.edges-count, $!dist.attractiveness, :$prefix);
            }

            when Graph::Distribution::WattsStrogatz:D {
                self!generate-watts-strogatz-graph($!dist.vertex-count, $!dist.p, :$prefix);
            }

            default {
                die "Uknown or un-implemented graph distribution.";
            }
        }
    }

    #------------------------------------------------------
    # For BarabasiAlbert distribution
    method !generate-barabasi-albert-graph(Int:D $n, Int:D $k, Str:D :$prefix = '') {
        my @vertexes = [$prefix ~ '0',];

        for 1 ..^ $n -> $i {
            my @degrees = @vertexes.elems == 1 ?? [1,] !! @vertexes.map: { self.vertex-in-degree($_) };
            my $vertexBag = (@vertexes Z=> @degrees).BagHash;
            $vertexBag.pick($k).map({ self.add-edge($prefix ~ $i, $_, 1, :!directed) });

            @vertexes.push($prefix ~ $i);
        }
    }

    #------------------------------------------------------
    # For SpatialGraphDistribution
    sub dist(@v1, @v2) {
        sqrt([+] (@v1 Z @v2).map({ ($_[0] - $_[1]) ** 2 }));
    }
    method !generate-spatial-graph(Int:D $n, Numeric:D $r, Int:D $d, Str:D :$prefix = '') {
        my @vertices = (^$n).map({ (rand xx $d).List });
        for @vertices.kv -> $i, $vi {
            for @vertices[$i+1 .. *].kv -> $j, $vj {
                if dist($vi, $vj) ≤ $r {
                    self.add-edge($prefix ~ $i.Str, $prefix ~ ($i + $j + 1).Str, 1);
                }
            }
        }

        self.vertex-coordinates = @vertices.kv.rotor(2).map({ $prefix ~ $_.head => $_.tail }).cache.Hash;

        my $vSet = self.vertex-list.Set;
        for (^$n).map({ $prefix ~ $_ }) -> $v {
            if $v ∉ $vSet { self.adjacency-list{$v} = %() }
        }
    }

    #------------------------------------------------------
    # For PriceGraphDistribution
    method !generate-de-solla-price-graph(Int:D $n, Int:D $k, Numeric:D $a, Str:D :$prefix = '') {
        my @vertexes = ["{ $prefix }0",];

        for 1 .. $n - 1 -> $i {
            my $new-vertex = $prefix ~ ($k + $i - 1);
            my @degrees = @vertexes.elems == 1 ?? [1,] !! @vertexes.map: { self.vertex-in-degree($_) };
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
    method !generate-watts-strogatz-graph(Int:D $n, Numeric:D $p, :$prefix = '') {
        my $k = 4;
        # Each node is connected to k nearest neighbors in ring topology

        for ^$n -> $i {
            for 1 ..^ ($k div 2 + 1) -> $j {
                self.add-edge($prefix ~ $i.Str, $prefix ~ (($i + $j) % $n).Str);
                self.add-edge($prefix ~ $i.Str, $prefix ~ (($i - $j + $n) % $n).Str);
            }
        }

        for ^$n -> $i {
            for 1 ..^ ($k div 2 + 1) -> $j {
                if rand < $p {
                    my $new-to;
                    repeat {
                        $new-to = (^$n).grep({ $_ != $i && self.adjacency-list{$prefix ~ $i.Str}.elems }).pick;
                    } until $new-to.defined;
                    self.add-edge($prefix ~ $i.Str, $prefix ~ $new-to.Str);
                    self.add-edge($prefix ~ $i.Str, $prefix ~ (($i + $j) % $n).Str);
                }
            }
        }
    }

    #------------------------------------------------------
    multi method new(Int:D $vertex-count, Int:D $edges-count, Str:D $prefix = '',
                     Bool:D :d(:directed-edges(:$directed)) = False) {
        my $dist = Graph::Distribution::Uniform.new(:$vertex-count, :$edges-count);
        self.bless(:$dist, :$prefix, :$directed);
    }

    multi method new(Int:D :v(:$vertex-count), Int:D :n(:$edges-count), Str:D :$prefix = '',
                     Bool:D :d(:directed-edges(:$directed)) = False) {
        my $dist = Graph::Distribution::Uniform.new(:$vertex-count, :$edges-count);
        self.bless(:$dist, :$prefix, :$directed);
    }

    #------------------------------------------------------
    multi method new($dist, Str:D :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:$dist, :$prefix, :$directed);
    }
}