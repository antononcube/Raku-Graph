#!/usr/bin/env raku
use v6.d;

use Graph;
use Graph::Grid;
use Graph::KnightTour;

my $method = 'random'; # 'backtracking'
my $tstart = now;
my $graph = Graph::KnightTour.new(4, 6).index-graph;
#my $graph = Graph::Grid.new(6, 6).index-graph;
say $graph.wl(VertexLabels => 'Name');
#$graph = $graph.directed-graph(method => 'random');
my $tend = now;
say "Time to generate: {$tend - $tstart}";

my $tstart2 = now;
my $start = '0';
my $end = '19'; #$graph.vertex-list».Int.max.Str;
say "Path from '$start' to '$end'.";
my @res = |$graph.find-hamiltonian-path($start, $end, :$method, number-of-attempts => 2000, degree => 3);
my $tend2 = now;

say "Time to find: {$tend2 - $tstart2}";
say "Length: {@res.elems}";
say @res;
