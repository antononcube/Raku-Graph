use v6.d;

use Graph;

class Graph::Indexed is Graph {
    multi method new(Graph:D $g, Int:D $r = 0) {
        my %index;
        my $index = $r;
        for $g.vertex-list -> $vertex {
            %index{$vertex} = $index++;
        }
        my %new-adjacency-list;
        for $g.edges(:dataset) -> %e {
            %new-adjacency-list{%index{%e<from>}}{%index{%e<to>}} = %e<weight>;
        }
        self.bless(:adjacency-list(%new-adjacency-list), :directed($g.directed), :vertex-coordinates($g.vertex-coordinates));
    }

    multi method new(@edges, Int:D $r = 0, Bool:D :d(:directed-edges(:$directed)) = False) {
        return Graph::Indexed.new(Graph.new(@edges, :$directed), $r);
    }
}