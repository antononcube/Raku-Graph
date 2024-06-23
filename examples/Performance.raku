#!/usr/bin/env raku
use v6.d;

use lib <. lib>;

use Graph;
use Graph::Random;
use Data::Importers;

#my @edges = data-import($*CWD ~ '/resources/large-graph.json');
#my $graph = Graph.new(@edges);

my $tstart = now;
my $graph = Graph::Random.new(1000, 1000);
my $tend = now;
say "Time to generate: {$tend - $tstart}";

say $graph;

my $tstart2 = now;
my @res = $graph.find-shortest-path('297', '328', method => 'a-star');
my $tend2 = now;
say "Time to find: {$tend2 - $tstart2}";
say @res;