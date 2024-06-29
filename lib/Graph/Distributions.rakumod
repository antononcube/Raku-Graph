use v6.d;

unit module Graph::Distributions;

#============================================================
# Graph Distributions
#============================================================

#| Bernoulli graph distribution class
class BernoulliGraphDistribution is export {
    has Int:D $.vertex-count is required;
    has Numeric $.p = 0.5;

    multi method new($vertex-count, $p) {
        self.bless(:$vertex-count, :$p);
    }

    multi method new(:n(:$vertex-count), :$p) {
        self.bless(:$vertex-count, :$p);
    }
}
#= Bernoulli graph distribution objects are specified with parameters for number of vertexes and edge probability.

#| Price's model graph distribution class
class PriceGraphDistribution is export {
    has Int:D $.vertex-count is required;
    has Int:D $.edges-count is required;
    has Numeric:D $.attractiveness is required;

    multi method new($vertex-count, $edges-count, $attractiveness) {
        self.bless(:$vertex-count, :$edges-count, :$attractiveness);
    }

    multi method new(:n(:$vertex-count), :m(:$edges-count), :a(:$attractiveness)) {
        self.bless(:$vertex-count, :$edges-count, :$attractiveness);
    }
}
#= de Solla Price's graph distribution objects are specified with parameters for number vertexes, number of increment edges, and an attractiveness parameter.


#| Uniform graph distribution class
class UniformGraphDistribution is export {
    has Int:D $.vertex-count is required;
    has Int:D $.edges-count is required;

    multi method new($vertex-count, $edges-count) {
        self.bless(:$vertex-count, :$edges-count);
    }

    multi method new(:n(:$vertex-count), :m(:$edges-count)) {
        self.bless(:$vertex-count, :$edges-count);
    }
}
#= Uniform graph distribution objects are specified with parameters for number vertexes and number of edges.
