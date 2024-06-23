#!/usr/bin/env raku
use v6.d;

use lib <. lib>;

use Graph;
use Graph::Random;
use Data::Importers;

my @edges = data-import($*CWD ~ '/resources/large-graph.json');

my $graph = Graph::Random.new(60, 60);
#my $graph = Graph.new(@edges);

my $tstart = now;
my @res = $graph.find-shortest-path('29', '32');
my $tend = now;
say "Time to find: {$tend - $tstart}";
say @res;