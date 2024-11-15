use v6.d;

use Graph;
class Graph::Indexed is Graph {
    multi method new(@edges, Int:D $r = 0, :with(:&as) = WhateverCode, Bool:D :d(:directed-edges(:$directed)) = False, :$prefix = '') {
        return Graph.new(@edges, :$directed).index-graph($r, :&as, :$prefix);
    }

    multi method new(Graph:D $g, Int:D $r = 0, :with(:&as) = WhateverCode, :d(:directed-edges(:$directed)) = Whatever, :$prefix = '') {
        return $g.index-graph($r, :&as, :$prefix);
    }
}