use v6.d;

use Graph;

# It is a good idea to have :$directed to be Whatever.
# Becomes False if &f(v1, v2) == &f(v2, v1).
class Graph::Relation is Graph {
    multi method new(&f, @v, $w is copy = Whatever, :with(:&as) is copy = WhateverCode, Bool:D :d(:directed-edges(:$directed)) = True) {
        if &as.isa(WhateverCode) { &as = {$_} }
        my @w;
        given $w {
            when Whatever { @w = @v }
            when $_ ~~ (Array:D | List:D | Seq:D) { @w = |$w }
            default {
                die 'The third argument is expected to be a list or Whatever.'
            }
        }
        my @edges = (@v X @w).map({ &f(&as($_.head), &as($_.tail)) ?? Pair.new($_.head.Str, $_.tail.Str) !! Empty });
        my Graph $graph = Graph.new(@edges, :$directed);
        return $graph;
    }
}