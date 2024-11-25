use v6.d;

use Graph;

class Graph::Nested is Graph {
    multi method new(&f, $expr, Int:D $n = 1, :with(:&as) = WhateverCode, Bool:D :d(:directed-edges(:$directed)) = False) {
        my Graph $graph = self!init-graph($expr, :$directed);
        for 1..$n {
            $graph = $graph.union(self!apply-f($graph, &f, :&as, :$directed));
        }
        return $graph;
    }

    method !init-graph($expr, Bool:D :$directed) {
        return do given $expr {
            when Graph { $expr }
            when Positional { Graph.new($expr».Str, Empty, :$directed) }
            default {
                Graph.new([$expr.Str,], Empty, :$directed);
            }
        }
    }

    method !apply-f(Graph $graph, &f, :&as is copy, Bool:D :$directed) {
        if &as.isa(WhateverCode) { &as = {$_} }
        my Graph $new-graph .= new(:$directed);
        for $graph.vertex-list -> $v {
            my @new-vertices = f(&as($v));
            for @new-vertices -> $nv {
                $new-graph.edge-add($v, $nv.Str, :$directed);
            }
        }
        return $new-graph;
    }
}