#!/usr/bin/env raku
use v6.d;

use Graph::Random;
use Graph::Distribution;

my $graph = Graph::Random.new(vertex-count => 12, edges-count => 16, prefix => '');

#say $graph;

say $graph.wl;

my $graph2 = Graph::Random.new(Graph::Distribution::Uniform.new(12, 20), prefix => 'd');

#say $graph2;

say $graph2.wl;

my $graph3 = Graph::Random.new(Graph::Distribution::Bernoulli.new(10, 0.6), prefix => 'b');

#say $graph3;

say $graph3.wl;

my $graph4 = Graph::Random.new(Graph::Distribution::Price.new(20, 2, 1), prefix => 'p');

#say $graph4;

say $graph4.wl;

my $graph5 = Graph::Random.new(Graph::Distribution::WattsStrogatz.new(50, 0.03), prefix => 'p');

#say $graph5;

say $graph5.wl;

my $graph6 = Graph::Random.new(Graph::Distribution::BarabasiAlbert.new(3, 2), prefix => 'ba');

#say $graph6;

say $graph6.wl;