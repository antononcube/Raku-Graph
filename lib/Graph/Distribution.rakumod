use v6.d;

unit module Graph::Distribution;

#============================================================
# Graph Distributions
#============================================================

#| BarabasiAlbert graph distribution class
class BarabasiAlbert is export {
    has Int:D $.vertex-count is required;
    has Int:D $.edges-count is required;

    multi method new($vertex-count, $edges-count) {
        self.bless(:$vertex-count, :$edges-count);
    }

    multi method new(:n(:$vertex-count), :k(:$edges-count)) {
        self.bless(:$vertex-count, :$edges-count);
    }
}
#= BarabasiAlbert graph distribution objects are specified with parameters for number of vertexes and number of increment edges.

#| Bernoulli graph distribution class
class Bernoulli is export {
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
class Price is export {
    has Int:D $.vertex-count is required;
    has Int:D $.edges-count is required;
    has Numeric:D $.attractiveness is required;

    multi method new($vertex-count, $edges-count, $attractiveness) {
        self.bless(:$vertex-count, :$edges-count, :$attractiveness);
    }

    multi method new(:n(:$vertex-count), :k(:$edges-count), :a(:$attractiveness)) {
        self.bless(:$vertex-count, :$edges-count, :$attractiveness);
    }
}
#= de Solla Price's graph distribution objects are specified with parameters for number of vertexes, number of increment edges, and an attractiveness parameter.

#| Spatial graph distribution class
class Spatial is export {
    has Int:D $.vertex-count is required;
    has Numeric:D $.radius is required;
    has Int:D $.dimension is required;

    multi method new(Int:D $vertex-count, Numeric:D $radius, Int:D $dimension = 2) {
        self.bless(:$vertex-count, :$radius, :$dimension);
    }

    multi method new(Int:D :n(:$vertex-count), Numeric:D :r(:$radius), Int:D :d(:$dimension) = 2) {
        self.bless(:$vertex-count, :$radius, :$dimension);
    }
}
#= Spatial graph distribution objects are specified with parameters for number of vertexes, max length of the edges (radius), and dimension of the unit hyper-cube.


#| Watts-Strogatz's model graph distribution class
class WattsStrogatz is export {
    has Int:D $.vertex-count is required;
    has Numeric:D $.p is required;

    multi method new($vertex-count, $p) {
        self.bless(:$vertex-count, :$p);
    }

    multi method new(:n(:$vertex-count), :$p) {
        self.bless(:$vertex-count, :$p);
    }
}
#= Watts-Strogatz graph distribution objects are specified with parameters for number vertexes and a rewiring parameter.


#| Uniform graph distribution class
class Uniform is export {
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
