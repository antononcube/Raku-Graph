#!/usr/bin/env raku
use v6.d;

use lib <. lib>;

use Graph::Random;
use Graph::Distribution;

# Technische Universität München example:
# https://algorithms.discrete.ma.tum.de/graph-algorithms/matchings-hungarian-method/index_en.html
my @dsEdges =
        %('from' => 'a', 'to' => 'e', 'weight' => 7),
        %('from' => 'a', 'to' => 'f', 'weight' => 4),
        %('from' => 'a', 'to' => 'g', 'weight' => 3),
        %('from' => 'a', 'to' => 'h', 'weight' => 5),
        %('from' => 'b', 'to' => 'e', 'weight' => 6),
        %('from' => 'b', 'to' => 'f', 'weight' => 8),
        %('from' => 'b', 'to' => 'g', 'weight' => 5),
        %('from' => 'b', 'to' => 'h', 'weight' => 9),
        %('from' => 'c', 'to' => 'e', 'weight' => 9),
        %('from' => 'c', 'to' => 'f', 'weight' => 4),
        %('from' => 'c', 'to' => 'g', 'weight' => 4),
        %('from' => 'c', 'to' => 'h', 'weight' => 2),
        %('from' => 'd', 'to' => 'e', 'weight' => 3),
        %('from' => 'd', 'to' => 'f', 'weight' => 8),
        %('from' => 'd', 'to' => 'g', 'weight' => 7),
        %('from' => 'd', 'to' => 'h', 'weight' => 4);

my $g = Graph.new(@dsEdges);

say $g.wl;

say "bipartite => ", $g.is-bipartite;

my $res = $g.hungarian-algorithm;

say $res;

#========================================================================================================================
say "=" x 120;

# FindIndependentEdgeSet example
my @dsEdges2 =
        %('from' => 'P1', 'to' => 'J1', 'weight' => 1), %('from' => 'P1', 'to' => 'J5', 'weight' => 1),
        %('from' => 'P2', 'to' => 'J1', 'weight' => 1), %('from' => 'P2', 'to' => 'J2', 'weight' => 1),
        %('from' => 'P3', 'to' => 'J2', 'weight' => 1), %('from' => 'P4', 'to' => 'J5', 'weight' => 1),
        %('from' => 'P4', 'to' => 'J2', 'weight' => 1), %('from' => 'P5', 'to' => 'J3', 'weight' => 1),
        %('from' => 'P6', 'to' => 'J1', 'weight' => 1), %('from' => 'P6', 'to' => 'J3', 'weight' => 1);


my $g2 = Graph.new(@dsEdges2);

say $g2.wl;

say "bipartite => ", $g2.is-bipartite;

my $res2 = $g2.hungarian-algorithm;

say $res2;
