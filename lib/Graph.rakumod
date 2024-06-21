use v6.d;

use Hash::Merge;

class Graph {
    has %.adjacency-list;
    has Bool:D $.directed = False;

    #------------------------------------------------------
    method edges(Bool:D :$dataset = False) {
        my @edges;
        my %mark;

        for %!adjacency-list.kv -> $from, %tos {
            for %tos.kv -> $to, $weight {
                if $!directed {
                    @edges.push({ :$from, :$to, :$weight })
                } else {
                    if !(%mark{$to}{$from} // False) {
                        @edges.push({:$from, :$to, :$weight });
                        %mark{$from}{$to} = True;
                    }
                }
            }
        }
        if $dataset {
            return @edges
        }
        return @edges.map({ $_<from> => $_<to> }).Array;
    }

    #------------------------------------------------------
    method edge-list(Bool:D :$dataset = False) {
        return self.edges(:!dataset);
    }

    #------------------------------------------------------
    method edge-count(--> Int) {
        return %!adjacency-list.elems;
    }

    #------------------------------------------------------
    method wl() {
        my @dsEdges = self.edges(:dataset);
        my $edges = @dsEdges.map({ "{$_<from>} -> {$_<to>}" }).join(', ');
        my $weights = @dsEdges.map({ $_<weight>.Str }).join(', ');

        "Graph[\{$edges\}, EdgeWeight -> \{$weights\}, DirectedEdges -> {$!directed}]";
    }

    #------------------------------------------------------
    method vertex-list() {
        my @res = %!adjacency-list.map({ $_.value.values }).flat.unique;
        @res.append(%%!adjacency-list.keys);

        return @res.List;
    }

    #------------------------------------------------------
    method vertex-count(--> Int) {
        return self.vertex-list().elems;
    }

    #------------------------------------------------------
    method add-edge(Str $from, Str $to, Int $weight = 1, Bool:D :d(:$directed) = False) {
        %.adjacency-list{$from}{$to} = $weight;

        if !$directed {
            %.adjacency-list{$to}{$from} = $weight;
        }
        $!directed = $directed;
    }

    #------------------------------------------------------
    method add-edges(@edges, Bool:D :d(:$directed) = False) {
        for @edges -> %edge {
            self.add-edge(%edge<from>, %edge<to>, %edge<weight> // 1, :$directed);
        }
    }

    #------------------------------------------------------
    method shortest-path(Str $start, Str $end) {
        my %distances = %.adjacency-list.keys.map({ $_ => Inf }).Hash;
        %distances{$start} = 0;
        my %previous;
        my @nodes = %.adjacency-list.keys;

        while @nodes {
            @nodes .= sort({ %distances{$^a} <=> %distances{$^b} });
            my $closest = @nodes.shift;

            last if %distances{$closest} == Inf;
            last if $closest eq $end;

            for %.adjacency-list{$closest}.keys -> $neighbor {
                my $alt = %distances{$closest} + %.adjacency-list{$closest}{$neighbor};
                if $alt < %distances{$neighbor} {
                    %distances{$neighbor} = $alt;
                    %previous{$neighbor} = $closest;
                }
            }
        }

        my @path;
        my $u = $end;
        while %previous{$u}:exists {
            unshift @path, $u;
            $u = %previous{$u};
        }
        unshift @path, $start if @path;

        return @path;
    }
}
