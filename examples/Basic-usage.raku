#!/usr/bin/env raku
use v6.d;

use Graph;

my @edges =
        { from => '1', to => '5', weight => 1 },
        { from => '1', to => '7', weight => 1 },
        { from => '2', to => '3', weight => 1 },
        { from => '2', to => '4', weight => 1 },
        { from => '2', to => '6', weight => 1 },
        { from => '2', to => '7', weight => 1 },
        { from => '2', to => '8', weight => 1 },
        { from => '2', to => '10', weight => 1 },
        { from => '2', to => '12', weight => 1 },
        { from => '3', to => '4', weight => 1 },
        { from => '3', to => '8', weight => 1 },
        { from => '4', to => '9', weight => 1 },
        { from => '5', to => '12', weight => 1 },
        { from => '6', to => '7', weight => 1 },
        { from => '9', to => '10', weight => 1 },
        { from => '11', to => '12', weight => 1 };

my $graph = Graph.new;
$graph.add-edges(@edges);

# Export graph as EPS image
#$graph.dot(engine => 'sfdp', output-format => 'eps') ==> spurt('./graph.eps');

# DOT graph spec with highlight
#note $graph.dot(highlight => [|<4 5 6 7>, "8" => "2"]);

say 'vertex count : ', $graph.vertex-count;
say 'vertex list : ', $graph.vertex-list;
say 'edge count : ', $graph.edge-count;

say "WL:\n", $graph.wl();

say 'find-shortest-path : ', $graph.find-shortest-path('1', '4');

say 'find-path : ' , $graph.find-path('1', '4', count => Inf).sort({ $_.elems ~ ' ' ~ $_.join(' ') });

say 'find-hamiltonian-path : ' , $graph.find-hamiltonian-path();

say 'find-hamiltonian-path from 1 to 4 : ' , $graph.find-hamiltonian-path('1', '4');

say 'find-hamiltonian-path from 8 to 11 : ' , $graph.find-hamiltonian-path('8', '11');

say 'find-cycle : ' , $graph.find-cycle().sort({ $_.elems ~ ' ' ~ $_.join(' ') });

say 'find-cycle (All): ' , $graph.find-cycle(count => Inf).sort({ $_.elems ~ ' ' ~ $_.join(' ') });
