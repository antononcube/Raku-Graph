#!/usr/bin/env raku
use v6.d;

use Graph;
use Graph::Random;
use Graph::Grid;
use Data::Importers;
use JSON::Fast;

#my @edges = data-import($*CWD ~ '/resources/large-graph.json');
#my $graph = Graph.new(@edges);

my $tstart = now;
my $graph = Graph::Grid.new(100, 100);
my $tend = now;
say "Time to generate: {$tend - $tstart}";

#my $tstart = now;
#my $graph = Graph::Random.new(1000, 4100);
#my $tend = now;
#say "Time to generate: {$tend - $tstart}";
#
#spurt($*CWD ~ '/resources/large-graph.json', to-json($graph.edges(:dataset)));

say $graph;

my $method = 'a-star';
my $tstart2 = now;
my @res = $graph.find-shortest-path('8_8', '88_88', :$method);
#my @res = $graph.find-shortest-path('297', '328', :$method);
my $tend2 = now;
say "Method : $method";
say "Time to find: {$tend2 - $tstart2}";
say "Length: {@res.elems}";
say @res;

#`[
my $tstart3 = now;
my $d = $graph.diameter();
my $tend3 = now;
say "Time to find: {$tend3 - $tstart3}";
say "Diameter: $d";
]

## Example outputs
#`[
    Time to generate: 2.804366067
    Graph(vertexes => 1000, edges => 1000, directed => False)
    Method : dijkstra
    Time to find: 0.514334823
    [297 39 921 241 137 529 253 328]
]

#`[
    Time to generate: 2.81529388
    Graph(vertexes => 1000, edges => 1000, directed => False)
    Method : a-star
    Time to find: 0.011091436
    [297 98 394 134 473 701 730 328]
]
