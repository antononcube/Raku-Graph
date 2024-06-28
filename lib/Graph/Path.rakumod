use v6.d;

use Graph;

class Graph::Path is Graph {
    has @.path is required;

    submethod BUILD(:@!path!, :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        for ^(@!path.elems - 1) -> $i {
            self.add-edge("{ $prefix }{ @!path[$i] }", "{ $prefix }{ @!path[$i + 1] }", :$directed);
        }
    }

    multi method new(Int:D $n, Str:D $prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(path => (^$n)».Str.cache, :$prefix, :$directed);
    }

    multi method new(Int:D :$n, Str:D :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(path => (^$n)».Str.cache, :$prefix, :$directed);
    }

    multi method new(@path, Str:D :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:@path, :$prefix, :$directed);
    }

    multi method new(:@path, Str:D :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:@path, :$prefix, :$directed);
    }
}

