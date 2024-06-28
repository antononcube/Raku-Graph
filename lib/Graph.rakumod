use v6.d;

use Hash::Merge;
use Data::TypeSystem;

class Graph {
    has %.adjacency-list;
    has Bool:D $.directed = False;

    #======================================================
    # Creators
    #======================================================
    submethod BUILD(:%!adjacency-list = %(), Bool:D :directed-edges(:$!directed) = False, :@edges?) {
        if @edges {
            self.add-edges(@edges, :$!directed)
        }
    }

    #------------------------------------------------------
    multi method new(:%adjacency-list = %(), Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:%adjacency-list, :$directed);
    }

    multi method new(@edges, Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(adjacency-list => %(), :$directed, :@edges);
    }

    #======================================================
    # Construction
    #======================================================
    method add-edge(Str $from, Str $to, Numeric $weight = 1, Bool:D :d(:$directed) = False) {
        %!adjacency-list{$from}{$to} = $weight;

        if !$directed {
            %!adjacency-list{$to}{$from} = $weight;
        }
        if $directed { $!directed = True; }
        return self;
    }

    #------------------------------------------------------
    method add-edges(@edges, Bool:D :d(:$directed) = False) {
        if is-reshapable(@edges, iterable-type => Positional, record-type => Map) {
            for @edges -> %edge {
                self.add-edge(%edge<from>, %edge<to>, %edge<weight> // 1, :$directed);
            }
        } elsif is-reshapable(@edges, iterable-type => Positional, record-type => Positional) {
            for @edges -> @edge {
                if !(@edge.elems ≥ 2 && @edge[^2].all ~~ Str:D) {
                    die "When the edges are specified as a Positional of Positionals " ~
                            "then edge record is expected to have two or three elements. " ~
                        "The first two record elements are expected to be strings; the third, if present, a number.";
                }
                self.add-edge(@edge[0], @edge[1], @edge[3] // 1, :$directed);
            }
        } else {
            die "The first argument is expected to be a Positional of Maps or a Positional of Positionals.";
        }
        return self;
    }

    #======================================================
    # Properties
    #======================================================
    method edges(Bool:D :$dataset = False) {
        my @edges;
        my %mark;

        for %!adjacency-list.kv -> $from, %tos {
            for %tos.kv -> $to, $weight {
                if $!directed {
                    @edges.push({ :$from, :$to, :$weight })
                } else {
                    if !(%mark{$to}{$from} // False) {
                        @edges.push({ :$from, :$to, :$weight });
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
        my $res = %!adjacency-list.map(*.value.elems).sum;
        return $!directed ?? $res !! $res div 2;
    }

    #------------------------------------------------------
    method vertex-list() {
        my @res = %!adjacency-list.map({ $_.value.keys }).flat.unique;
        @res.append(%!adjacency-list.keys);

        return @res.unique.sort.List;
    }

    #------------------------------------------------------
    method vertex-count(--> Int) {
        return self.vertex-list().elems;
    }

    #------------------------------------------------------
    method vertex-in-degree(Str:D $v--> Int) {
        return do if $!directed {
            self.adjacency-list{*;$v}.flat.grep(*.defined).elems;
        } else {
            self.vertex-degree($v);
        }
    }

    #------------------------------------------------------
    method vertex-out-degree(Str:D $v--> Int) {
        return do if $!directed {
            self.adjacency-list{$v}.elems // 0;
        } else {
            self.vertex-degree($v);
        }
    }

    #------------------------------------------------------
    method vertex-degree(Str:D $v--> Int) {
        return do if $!directed {
            self.vertex-out-degree($v) - self.vertex-in-degree($v);
        } else {
            self.adjacency-list{$v}.elems // 0;
        }
    }

    #======================================================
    # Representation
    #======================================================
    multi method gist(::?CLASS:D:-->Str) {
        return "Graph(vertexes => {self.vertex-count}, edges => {self.edge-count}, directed => {self.directed})";
    }

    method Str(){
        return self.gist();
    }

    #------------------------------------------------------
    sub to-wl-value($x) {
        return do given $x {
            when ($_ ~~ Str:D) && ($_ ~~ / ^ '`' .* '`' $ /) { $_.substr(1, $_.chars - 2) }
            when ($_ ~~ Str:D) && ($_ ~~ / ^ '${' .* '}' $ /) { $_.substr(1, $_.chars - 3) }
            when Str:D { '"' ~ $_ ~ '"' }
            default { $_.Str }
        };
    }

    method wl(*%args) {
        my @dsEdges = self.edges(:dataset);
        my $edges = @dsEdges.map({ "\"{ $_<from> }\" -> \"{ $_<to> }\"" }).join(', ');
        my $weights = @dsEdges.map({ $_<weight>.Str }).join(', ');

        my $args = '';
        if %args {
            $args = ', ' ~ %args.map({ "{$_.key} -> { to-wl-value($_.value) }" }).join(', ');
        }

        return "Graph[\{$edges\}, EdgeWeight -> \{$weights\}, DirectedEdges -> { $!directed }{ $args }]";
    }

    #------------------------------------------------------
    method mermaid(Str:D :d(:$direction) = 'LR', :$weights is copy = Whatever) {

        my @dsEdges = self.edges(:dataset);

        my $arrow = $!directed ?? '-->' !! '---';

        my $allOne = [&&] @dsEdges.map({ $_<weight> == 1 });

        my $edges =
                do if $weights.isa(Whatever) && $allOne || ($weights ~~ Bool:D) && !$weights {
                    @dsEdges.map({ "{ $_<from> } $arrow { $_<to> }" }).join("\n");
                } else {
                    @dsEdges.map({ "{ $_<from> } $arrow |{ $_<weight>.Str }|{ $_<to> }" }).join("\n");
                }

        "graph $direction\n$edges";
    }

    #------------------------------------------------------
    method dot(:$weights is copy = Whatever) {

        my @dsEdges = self.edges(:dataset);

        my $arrow = $!directed ?? '->' !! '--';

        my $allOne = [&&] @dsEdges.map({ $_<weight> == 1 });

        my $edges =
                do if $weights.isa(Whatever) && $allOne || ($weights ~~ Bool:D) && !$weights {
                    @dsEdges.map({ "\"{ $_<from> }\" $arrow \"{ $_<to> }\"" }).join("\n");
                } else {
                    @dsEdges.map({ "\"{ $_<from> }\" $arrow \"{ $_<to> }\" [weight={$_<weight>.Str }, label={$_<weight>.Str }]" }).join("\n");
                }

        "{$!directed ?? 'digraph' !! 'graph'} \{\n$edges\n\}";
    }

    #------------------------------------------------------
    method graphml() {
        my $xml = qq:to/END/;
        <?xml version="1.0" encoding="UTF-8"?>
        <graphml xmlns="http://graphml.graphdrawing.org/xmlns"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xsi:schemaLocation="http://graphml.graphdrawing.org/xmlns
                                 http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd">
        <graph edgedefault="{ $!directed ?? 'directed' !! 'undirected' }">
        END

        for %.adjacency-list.kv -> $from, %to {
            $xml ~= qq:to/END/;
            <node id="{ $from }"/>
            END

            for %to.kv -> $to, $weight {
                $xml ~= qq:to/END/;
                <node id="{ $to }"/>
                <edge source="{ $from }" target="{ $to }" weight="{ $weight }"/>
                END
            }
        }

        $xml ~= qq:to/END/;
        </graph>
        </graphml>
        END

        return $xml;
    }

    #======================================================
    # Shortest paths algorithms
    #======================================================
    method find-shortest-path(Str $start, Str $end, :$method is copy = Whatever) {
        if $method.isa(Whatever) { $method = 'dijkstra' }
        die 'The value of $method is expected to be Whatever or one of "dijkstra" or "a-star-search".'
        unless $method ~~ Str:D;

        return do given $method.lc {
            when $_ eq 'dijkstra' { self!dijkstra-shortest-path($start, $end); }
            when $_ ∈ <a* a-star a-star-search> { self!a-star-shortest-path($start, $end); }
            default {
                die 'Do not know how to process the given method.'
            }
        }
    }

    #------------------------------------------------------
    # Dijkstra's algorithm, two nodes
    method !dijkstra-shortest-path(Str $start, Str $end) {
        my %distances = %.adjacency-list.keys.map({ $_ => Inf }).Hash;
        %distances{$start} = 0;
        my %previous;
        my @nodes = %.adjacency-list.keys;
        my $visited = SetHash.new;

        while @nodes {
            @nodes .= sort({ %distances{$^a} <=> %distances{$^b} });
            my $closest = @nodes.shift;

            last if %distances{$closest} == Inf;
            last if $closest eq $end;

            for %.adjacency-list{$closest}.keys -> $neighbor {
                if ! $visited{$neighbor} {
                    my $alt = %distances{$closest} + %.adjacency-list{$closest}{$neighbor} // Inf;
                    if $alt < %distances{$neighbor} {
                        %distances{$neighbor} = $alt;
                        %previous{$neighbor} = $closest;
                    }
                }
            }
            $visited.set($closest)
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

    #------------------------------------------------------
    # Dijkstra's algorithm to all other vertexes
    method !dijkstra-shortest-path-distances(Str $start) {
        my %distances;
        my %visited;
        my @queue = [[$start, 0], ];

        while @queue {
            my ($current, $dist) = @queue.shift;
            next if %visited{$current}:exists;
            %visited{$current} = True;
            %distances{$current} = $dist;

            for %.adjacency-list{$current}.keys -> $neighbor {
                unless %visited{$neighbor}:exists {
                    @queue.push([$neighbor, $dist + %.adjacency-list{$current}{$neighbor}] );
                }
            }
            @queue .= sort({ $^a[1] <=> $^b[1] });
        }

        return %distances;
    }

    #------------------------------------------------------
    # A* search
    method !a-star-shortest-path(Str $start, Str $end, :&heuristic is copy = WhateverCode) {
        # Placeholder for actual heuristic function
        if &heuristic.isa(WhateverCode) {
            &heuristic = -> Str $a, Str $b { 1 };
        }

        my %open-set = $start => 0;
        my %came-from;
        my %g-score = $start => 0;
        my %f-score = $start => heuristic($start, $end);

        while %open-set {
            my $current = %open-set.keys.sort({ %f-score{$_} }).first;
            return gather {
                my $node = $current;
                while %came-from{$node}:exists {
                    take $node;
                    $node = %came-from{$node};
                }
                take $start;
            }.reverse if $current eq $end;

            %open-set{$current}:delete;
            for %.adjacency-list{$current}.keys -> $neighbor {
                my $tentative-g-score = %g-score{$current} + %.adjacency-list{$current}{$neighbor};
                if %g-score{$neighbor}:!exists || $tentative-g-score < %g-score{$neighbor} {
                    %came-from{$neighbor} = $current;
                    %g-score{$neighbor} = $tentative-g-score;
                    %f-score{$neighbor} = %g-score{$neighbor} + heuristic($neighbor, $end);
                    %open-set{$neighbor} = %f-score{$neighbor} unless %open-set{$neighbor}:exists;
                }
            }
        }
        return []; # No path found
    }

    #======================================================
    # Find paths
    #======================================================
    multi method find-path(Str $s, Str $t, :$min-length = 0, :$max-length = Inf, :$count = 1) {
        self!dfs($s, $t, :$min-length, :$max-length, :$count);
    }

    method !dfs(Str $s, Str $t, :$min-length = 0, :$max-length = Inf, :$count = 1) {
        my @paths;
        my @stack = [[$s, [$s,], 0],];
        # current node, path, length
        while @stack && @paths.elems < $count {
            my ($current, $path, $length) = @stack.pop;
            #note (:$current, :$path, :$length);
            if $current eq $t && $length >= $min-length && $length <= $max-length {
                @paths.push($path);
            } elsif $length < $max-length {
                for %.adjacency-list{$current}.keys -> $neighbor {
                    unless $neighbor ∈ $path {
                        @stack.push([$neighbor, [|$path, $neighbor], $length + 1]);
                    }
                }
            }
        }
        return @paths;
    }

    #======================================================
    # Find Hamiltonian paths
    #======================================================
    multi method find-hamiltonian-path() {
        self!hamiltonian-path-helper();
    }

    multi method find-hamiltonian-path(Str $s, Str $t) {
        self!hamiltonian-path-helper($s, $t);
    }

    method !hamiltonian-path-helper(Str $s?, Str $t?) {
        my @vertices = %.adjacency-list.keys;
        my @best-path;
        my $best-length = Inf;

        sub hamiltonian-path(@path, %visited, $length) {
            if @path.elems == @vertices.elems {
                if !$s.defined || @path.head eq $s && (!$t.defined || @path.tail eq $t) {
                    if $length < $best-length {
                        @best-path = @path;
                        $best-length = $length;
                    }
                }
                return;
            }

            for %.adjacency-list{@path.tail}.keys -> $neighbor {
                unless %visited{$neighbor} {
                    %visited{$neighbor} = True;
                    hamiltonian-path(
                            [|@path, $neighbor],
                            %visited,
                            $length + %.adjacency-list{@path.tail}{$neighbor});
                    %visited{$neighbor} = False;
                }
            }
        }

        for @vertices -> $start {
            my %visited = $start => True;
            hamiltonian-path([$start], %visited, 0);
        }

        return @best-path;
    }

    #======================================================
    # Find cycles
    #======================================================
    method find-cycle(:$min-length = 3, :$max-length = Inf, :$count = 1) {
        self!find-cycle-helper(:$min-length, :$max-length, :$count);
    }

    #------------------------------------------------------
    sub rotate-to-smallest(@strings, Bool:D :$directed!) {
        my $smallest = @strings.sort.head;
        my @strings2 = @strings.clone.rotate(@strings.first($smallest,:k));
        if !$directed {
            my @r1 = @strings2.tail(*-1);
            my @r2 = @r1.reverse;

            @strings2 = do given @r1 cmp @r2 {
                when Less { [@strings2.head, |@r1, @strings2.head] }
                default { [@strings2.head, |@r2, @strings2.head] }
            }
        }
        return @strings2;
    }

    #------------------------------------------------------
    method !find-cycle-helper(:$min-length = 3, :$max-length = Inf, :$count = Inf) {
        my @cycles;
        my %visited;
        my $found = 0;

        sub cycle-dfs($node, @path) {

            my $parent = @path.tail;

            if %visited{$node} && @path.elems > 1 {
                if @path.elems ≥ $min-length && @path.elems ≤ $max-length {
                    my $index = @path.first(* eq $node, :k);
                    #my @candidate = [|@path[$index..*], $node];
                    my @candidate = rotate-to-smallest(@path[$index..*].clone, :$!directed);
                    my $cind = @cycles.first({ $_ eqv @candidate });
                    without $cind {
                        @cycles.push(@candidate);
                        $found++;
                    }
                    return;
                }
            }

            %visited{$node} = True;
            @path.push($node);

            for %.adjacency-list{$node}.keys -> $neighbor {
                cycle-dfs($neighbor, @path) if $neighbor ∉ [$node, $parent];
                last if $found >= $count;
            }

            @path.pop;
            %visited{$node} = False;
        }

        for %.adjacency-list.keys -> $start {
            %visited = %();
            cycle-dfs($start, []);
            last if $found >= $count;
        }

        return @cycles;
    }

    #======================================================
    # Measures
    #======================================================
    method vertex-eccentricity($v --> Numeric) {
        # The distance between two vertices in a graph is the number of edges in a shortest path connecting them.
        # The eccentricity ϵ(v) of a vertex v is the greatest distance between v and any other vertex.
        my %distances = self!dijkstra-shortest-path-distances($v);
        if %distances.elems < self.vertex-count { return Inf; }
        return %distances.values.max;
    }

    method diameter(--> Numeric) {
        # To find the diameter of a graph, first find the shortest path between each pair of vertices.
        # The greatest length of any of these paths is the diameter of the graph.
        # It represents the longest shortest path between any two vertices in the graph.
        my $max-distance = 0;
        my $nv = self.vertex-count;
        for %.adjacency-list.keys -> $start {
            my %distances = self!dijkstra-shortest-path-distances($start);
            if %distances.elems < $nv { return Inf; }
            my $eccentricity = %distances.values.max;
            if $eccentricity > $max-distance { $max-distance = $eccentricity; }
        }
        return $max-distance;
    }

    method radius(--> Numeric) {
        # The radius of a graph is the minimum eccentricity of any vertex in that graph.
        # The radius is the smallest maximum distance from any vertex to all other vertices in the graph.
        my $min-eccentricity = Inf;
        my $nv = self.vertex-count;
        for %.adjacency-list.keys -> $start {
            my %distances = self!dijkstra-shortest-path-distances($start);
            if %distances.elems < $nv { return Inf; }
            my $eccentricity = %distances.values.max;
            $min-eccentricity = $eccentricity if $eccentricity < $min-eccentricity;
        }
        $min-eccentricity;
    }

    method center(--> Numeric) {
        my %eccentricities = %.adjacency-list.keys.map({ $_ => self.vertex-eccentricity($_) });
        my $me = %eccentricities.values.min;
        return %eccentricities.grep({ $_.value == $me });
    }

    method periphery(--> Numeric) {
        my %eccentricities = %.adjacency-list.keys.map({ $_ => self.vertex-eccentricity($_) });
        my $me = %eccentricities.values.max;
        return %eccentricities.grep({ $_.value == $me });
    }
}
