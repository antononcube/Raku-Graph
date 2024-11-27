#!/usr/bin/env raku
use v6.d;

use lib <. lib>;
use Graph;
use Graph::Grid;
use Graph::KnightTour;
use Data::Reshapers;
use Data::Summarizers;

my $method = 'random'; # 'backtracking'
my $max-number-of-attempts = 2000;
my $n-trials = 100;
my $pick = 'max-degree';

my $tstart = now;
#my $graph = Graph::KnightTour.new(4, 6).index-graph;
my $graph = Graph::Grid.new(5, 6).index-graph;
say $graph.wl(VertexLabels => 'Name');
#$graph = $graph.directed-graph(method => 'random');
my $tend = now;
say "Time to generate: {$tend - $tstart}";

my $tstart2 = now;
my $start = '0';
my $end = $graph.vertex-list».Int.max.Str; # '19'
say "Path from '$start' to '$end'.";
my @res = |$graph.find-hamiltonian-path($start, $end, :$method, :$max-number-of-attempts, degree => 1, :$pick);
my $tend2 = now;

say "Time to find: {$tend2 - $tstart2}";
say "Length: {@res.elems}";
say @res;


if $method eq 'random' {
    my @attempts = do for ^$n-trials {
        say "attempt: $_ ";
        my $n = [Whatever, $max-number-of-attempts].pick;
        my $tstart = now;
        # :$n is a synonym of :$max-number-of-attempts
        my @path = $graph.find-hamiltonian-path($start, $end, :$method, :$n, :$pick);
        my $tend = now;

        %(max-number-of-attempts => $n, success => @path.elems > 0, elems => @path.elems, time => $tend - $tstart)
    }

    .say for @attempts;

    records-summary(@attempts)
}