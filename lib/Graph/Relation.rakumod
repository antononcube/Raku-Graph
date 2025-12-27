use v6.d;

use Graph;

# It is a good idea to have :$directed to be Whatever.
# Becomes False if &f(v1, v2) == &f(v2, v1).
# It is also a good idea to have the :$degree and :$batch arguments, since Cartesian product of the @v and $w arguments is made.
class Graph::Relation is Graph {
    multi method new(&f,                                 #= Function indicating relationship.
                     @v,                                 #= Elements to find relationships.
                     $w is copy = Whatever,              #= Elements to find relationships; if Whatever then is the same as @v.
                     :with(:&as) is copy = WhateverCode, #= Function to apply to each element for making it a graph vertex.
                     :d(:directed-edges(:$directed)) is copy = Whatever, #= Whether the graph be directed or not; if Whatever becomes False if &f(v1, v2) == &f(v2, v1) for all argument pairs.
                     ) {
        if &as.isa(WhateverCode) { &as = {$_} }
        given $w {
            when Whatever { $w = @v }
            when $_ ~~ (Array:D | List:D | Seq:D) {
                # do nothing
            }
            default {
                die 'The third argument is expected to be a list or Whatever.'
            }
        }

        my @edges;
        given $directed {
            when $_ ~~ Bool:D {
                @edges = (@v X $w.Array).map({ &f($_.head, $_.tail) ?? Pair.new($_.head.&as.Str, $_.tail.&as.Str) !! Empty });
            }
            when Whatever {
                $directed = False;
                for (@v X $w.Array) {
                    my $res = &f($_.head, $_.tail);
                    if $res {
                        @edges.push(Pair.new($_.head.&as.Str, $_.tail.&as.Str))
                    }

                    $directed = True if !$directed && $res ne &f($_.tail, $_.head);
                }
            }
            default {
                die 'The argument :$directed is expected to be a Boolean or Whatever.'
            }
        }

        my Graph $graph = Graph.new(@edges, :$directed);
        return $graph;
    }
}