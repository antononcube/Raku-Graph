use v6.d;

use Graph;

class Graph::Complete is Graph {
    has @.n is required;

    submethod BUILD(:@!n!, :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        if @!n.elems == 1 {
            my $n = @!n.head;
            for 1 .. $n -> $i {
                for 1 .. $n -> $j {
                    next if $i == $j;
                    self.edge-add("$prefix$i", "$prefix$j", :$directed);
                    if $directed {
                        self.edge-add("$prefix$j", "$prefix$i", :$directed);
                    }
                }
            }
        } else {
            my @vertices;
            my @edges;
            my %vertex-coordinates;
            for @!n.kv -> $i, $k {
                my @level = "{$prefix}{$i}_" X~ (^$k);
                my %coords = @level Z=> cross($i, (^$k) <<->> (($k -1) / 2));
                %vertex-coordinates = %vertex-coordinates , %coords;
                if $i > 0 {
                    my @level-edges = @vertices X=> @level;
                    @edges = @edges.append(@level-edges)
                }
                @vertices.append(@level)
            }
            self.vertex-coordinates = %vertex-coordinates;
            self.edge-add(@edges, :$directed)
        }
    }

    multi method new(Int:D $n, Str:D $prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {

        die 'A single first argument is expected to be a non-negative integer.'
        unless $n ~~ Int:D && $n ≥ 0;

        self.bless(n => [$n,], :$prefix, :$directed);
    }

    multi method new(@n, Str:D :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:@n, :$prefix, :$directed);
    }

    multi method new(:@n, Str:D :$prefix = '', Bool:D :d(:directed-edges(:$directed)) = False) {

        die 'At least one element is expected.'
        unless @n;

        die 'All elements of the first argument are expected to be positive integers.'
        unless @n.all ~~ Int:D && @n.all ≥ 0;

        self.bless(:@n, :$prefix, :$directed);
    }
}

