#!/usr/bin/env raku
use v6.d;

use lib <. lib>;

use Graph::Random;

my $graph = Graph::Random.new(vertex-count => 12, edge-count => 16, prefix => '');

say $graph;

say $graph.mermaid;
