#!/usr/bin/env raku
use v6.d;

use lib <. lib>;

use Graph::Random;
use Graph::Distributions;

my $graph = Graph::Random.new(vertex-count => 12, edges-count => 16, prefix => '');

#say $graph;

say $graph.wl;

my $graph2 = Graph::Random.new(UniformGraphDistribution.new(12, 20), prefix => 'd');

#say $graph2;

say $graph2.wl;

my $graph3 = Graph::Random.new(BernoulliGraphDistribution.new(10, 0.6), prefix => 'b');

#say $graph3;

say $graph3.wl;

my $graph4 = Graph::Random.new(PriceGraphDistribution.new(20, 2, 1), prefix => 'p');

#say $graph4;

say $graph4.wl;
