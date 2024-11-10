use v6.d;

use BinaryHeap;
use Data::TypeSystem;
use Graph::Bipartitish;
use Graph::Componentish;
use Graph::Formatish;
use Graph::Tourish;
use Graph::Neighborhoodish;

class Graph
        does Graph::Bipartitish
        does Graph::Componentish
        does Graph::Formatish
        does Graph::Neighborhoodish
        does Graph::Tourish {
    has %.adjacency-list;
    has Bool:D $.directed = False;
    has $.vertex-coordinates is rw = Whatever;

    #======================================================
    # Creators
    #======================================================
    submethod BUILD(:%!adjacency-list = %(),
                    Bool:D :directed-edges(:$!directed) = False,
                    :@vertexes = Empty,
                    :@edges = Empty,
                    :$!vertex-coordinates = Whatever) {
        if @edges {
            self.add-edges(@edges, :$!directed)
        }

        if @vertexes {
            for @vertexes -> $v {
                if %!adjacency-list{$v}:!exists {
                    self.adjacency-list.push( $v => %() );
                }
            }
        }
    }

    #------------------------------------------------------
    multi method new(:%adjacency-list = %(), Bool:D :d(:directed-edges(:$directed)) = False, :$vertex-coordinates = Whatever) {
        self.bless(:%adjacency-list, :$directed, :$vertex-coordinates);
    }

    multi method new(@edges, Bool:D :d(:directed-edges(:$directed)) = False, :$vertex-coordinates = Whatever) {
        self.bless(adjacency-list => %(), :$directed, :@edges, :$vertex-coordinates);
    }

    multi method new(@vertexes, @edges, Bool:D :d(:directed-edges(:$directed)) = False, :$vertex-coordinates = Whatever) {
        self.bless(adjacency-list => %(), :$directed, :@vertexes, :@edges, :$vertex-coordinates);
    }

    multi method new(:@vertexes!, :@edges!, Bool:D :d(:directed-edges(:$directed)) = False, :$vertex-coordinates = Whatever) {
        self.bless(adjacency-list => %(), :$directed, :@vertexes, :@edges, :$vertex-coordinates);
    }

    multi method new(Graph:D $gr, :d(:directed-edges(:$directed)) is copy = Whatever, :$vertex-coordinates = Whatever) {

        if $directed.isa(Whatever) { $directed = $gr.directed; }
        die "When the first argument is a graph then the value of \$directed is expected to be a Boolean or Whatever."
        unless $directed ~~ Bool:D;

        my @edges = $gr.edges(:dataset);
        self.bless(adjacency-list => %(), :$directed, :@edges, :$vertex-coordinates);
    }

    method clone(:d(:$directed) is copy = Whatever) {
        if $directed.isa(Whatever) {$directed = $!directed}
        die 'The value of the argument $directed is expected to be a Boolean or Whaterver.'
        unless $directed ~~ Bool:D;

        # This can be probably made faster by cloning the adjacency-list directly.
        my @edges = self.edges(:dataset);
        given ($directed, $!directed) {
            when $_ eqv (True, False) {
                @edges = [|@edges, |@edges.map({ %( from => $_<to>, to => $_<from>, weight => $_<weight>) })];
            }
            # when (True, True) { done by default with creation }
            # when (False, False) { done by default with creation }
            # when (False, True) { done by default with creation }
        }
        return Graph.new(self.vertex-list, @edges, :$directed, :$!vertex-coordinates);
    }

    #======================================================
    # Basic predicates
    #======================================================
    method has-vertex(Str:D $v --> Bool:D) {
        return (%!adjacency-list{$v}:exists) || %!adjacency-list{*;$v}.flat.grep(*.defined).elems > 0;
    }

    #------------------------------------------------------
    method has-edge(Str:D $from, Str:D $to --> Bool:D) {
        # For undirected graphs both
        # %!adjacency-list{$from}{$to} and %!adjacency-list{$to}{$from}
        # should be in.
        return so %!adjacency-list{$from}{$to};
    }

    #------------------------------------------------------
    method is-empty(--> Bool:D) {
        return %!adjacency-list.elems == 0 || %!adjacency-list.map(*.value.elems).sum == 0;
    }

    #======================================================
    # Construction
    #======================================================
    multi method vertex-add(Str:D $v) {
        return self.vertex-add([$v,])
    }

    multi method vertex-add(@vertexes) {
        for @vertexes -> $v {
            if !self.has-vertex($v) {
                self.adjacency-list{$v} = %();
            }
        }
        return self;
    }

    #------------------------------------------------------
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
        } elsif @edges.all ~~ Pair:D {
            return self.add-edges(@edges».kv».List.List, :$directed);
        } else {
            die "The first argument is expected to be a Positional of Maps or a Positional of Positionals.";
        }
        return self;
    }

    #======================================================
    # Vertex removal
    #======================================================
    multi method vertex-delete(Str:D $v) {
        %!adjacency-list{$v}:delete;
       for %!adjacency-list.kv -> $k, %vertexes {
            if %vertexes{$v}:exists {
                %vertexes{$v}:delete
            }
            if ($!vertex-coordinates ~~ Map:D) && ($!vertex-coordinates{$v}:exists) {
                $!vertex-coordinates{$v}:delete
            }
        }
        return self;
    }

    multi method vertex-delete(@vs) {
        for @vs -> $v { self.vertex-delete($v) }
        return self;
    }

    multi method vertex-delete(Regex $rx) {
        my @vs = self.vertex-list.grep({ $_ ~~ $rx });
        return self.vertex-delete(@vs);
    }

    #======================================================
    # Edge removal
    #======================================================
    multi method edge-delete(Str:D :$from, Str:D :$to) {
        with %!adjacency-list{$from}{$to} {
            %!adjacency-list{$from}{$to}:delete;
            # We do not do the following, because removing an edge does not mean removing its vertexes too.
            # if %!adjacency-list{$from}.elems == 0 { %!adjacency-list{$from}:delete; }
        }
        if !$!directed && %!adjacency-list{$to}{$from}.defined {
            %!adjacency-list{$to}{$from}:delete;
            # We do not do the following, because removing an edge does not mean removing its vertexes too.
            # if %!adjacency-list{$to}.elems == 0 { %!adjacency-list{$to}:delete; }
        }
        #`[
        my @edges = self.edges(:dataset);
        @edges = do if $!directed {
            @edges.grep({ !($_<from> eq $from && $_<to> eq $to) })
        } else {
            @edges.grep({ !($_<from> eq $from && $_<to> eq $to || $_<to> eq $from && $_<from> eq $to) })
        }

        %!adjacency-list = Empty;
        self.add-edges(@edges, :$!directed);
        ]
        return self;
    }

    multi method edge-delete(Str:D $from, Str:D $to) {
        return self.edge-delete(:$from, :$to);
    }

    multi method edge-delete(Pair $p) {
        return self.edge-delete(from => $p.key, to => $p.value);
    }

    multi method edge-delete(%edge) {
        if (%edge<from> // False) && (%edge<to> // False) {
            return self.edge-delete(%edge<from>, %edge<to>);
        }
        return self;
    }

    multi method edge-delete(@edges where @edges.all ~~ Pair:D) {
        for @edges -> $p { self.edge-delete($p) }
        return self;
    }

    multi method edge-delete(@edges where @edges.all ~~ Map:D) {
        for @edges -> %e { self.edge-delete(%e) }
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
                        my ($f, $t) = ($from, $to).sort;
                        @edges.push({ from => $f, to => $t, :$weight });
                        %mark{$from}{$to} = True;
                    }
                }
            }
        }
        if $dataset {
            return @edges
        }
        return @edges.sort(*<from to>).map({ $_<from> => $_<to> }).Array;
    }

    #------------------------------------------------------
    method edge-list(Bool:D :$dataset = False) {
        return self.edges(:!dataset);
    }

    #------------------------------------------------------
    method edge-count(--> Int) {
        if $!directed {
            # Assuming this is faster.
            return %!adjacency-list.map(*.value.elems).sum;
        } else {
            return self.edges.elems;
        }
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
    # Basic conversions
    #======================================================
    method undirected-graph() {
        return self.clone(:!directed);
    }

    method directed-graph(:m(:$method) = Whatever) {
        return do if $!directed {
            self.clone;
        } else {
            given $method {
                when Whatever {
                    self.clone(:directed)
                }
                when $_ ~~ Str:D && $_.lc eq 'acyclic' {
                    my @edges = self.edges(:dataset);
                    my %vertexToInd = self.vertex-list.sort.kv.Hash.invert;
                    @edges = @edges.map({ %vertexToInd{$_<from>} < %vertexToInd{$_<to>} ?? $_ !! %( from => $_<to>, to => $_<from>, weight => $_<weight>) });
                    Graph.new(@edges, :directed)
                }
                when $_ ~~ Str:D && $_.lc eq 'random' {
                    my @edges = self.edges(:dataset);
                    @edges = @edges.map({ rand < 0.5 ?? $_ !! %( from => $_<to>, to => $_<from>, weight => $_<weight>) });
                    Graph.new(@edges, :directed)
                }
                default {
                    die 'The value of $method is expected to be "Acyclic", "Random", or Whatever.';
                }
            }
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
        my $visited = SetHash.new;

        my BinaryHeap::MinHeap[{ $^a.tail cmp $^b.tail }] $h;
        $h.push([$start, %distances{$start}]);

        while $h {
            my ($closest, $dist) = $h.pop;

            last if %distances{$closest} == Inf;
            last if $closest eq $end;

            for %.adjacency-list{$closest}.keys -> $neighbor {
                if ! $visited{$neighbor} {
                    my $alt = %distances{$closest} + %.adjacency-list{$closest}{$neighbor} // Inf;
                    if $alt < %distances{$neighbor} {
                        %distances{$neighbor} = $alt;
                        %previous{$neighbor} = $closest;
                        $h.push([$neighbor, $alt])
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

        my BinaryHeap::MinHeap[{ $^a[1] <=> $^b[1] }] $h;
        $h.push(@queue.head);

        while $h {
            my ($current, $dist) = $h.pop;

            next if %visited{$current}:exists;
            %visited{$current} = True;
            %distances{$current} = $dist;

            for %.adjacency-list{$current}.keys -> $neighbor {
                unless %visited{$neighbor}:exists {
                    $h.push([$neighbor, $dist + %.adjacency-list{$current}{$neighbor}] );
                }
            }
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

        my BinaryHeap::MinHeap[{ $^a.tail <=> $^b.tail }] $h;
        $h.push([$start, %f-score{$start}]);

        while %open-set {
            ## Original implementation -- should explain why I keep %open-set below.
            #my $current = %open-set.keys.min({ %f-score{$_} });
            ## Optimization
            my ($current, $score) = $h.pop;

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
                    {
                        %open-set{$neighbor} = %f-score{$neighbor};
                        $h.push([$neighbor, %f-score{$neighbor}]);
                    } unless %open-set{$neighbor}:exists;
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
    # Spanning tree
    #======================================================
    method find-spanning-tree(:$method is copy = Whatever) {

        if $method.isa(Whatever) { $method = 'kruskal'; }
        die 'The value of $method is expected to be a string or Whatever.'
        unless $method ~~ Str:D;

        return do given $method {
            when 'kruskal' {
                Graph.new(self!minimum-spanning-tree-kruskal())
            }
            when 'prim' {
                Graph.new(adjacency-list => self!minimum-spanning-tree-prim(), :!directed)
            }
            default {
                die 'Unknown specified method.';
            }
        }

    }

    method !minimum-spanning-tree-kruskal() {
        my @dsEdges = self.edges(:dataset);
        @dsEdges = @dsEdges.sort({ $_<weight> });

        my @vertexes = self.vertex-list;
        my $n = @vertexes.elems;
        my %hh;
        my @span;

        for @vertexes -> $v {
            %hh{$v} = [$v,];
        }

        for @dsEdges -> %edge {
            my ($c1, $c2) = (%hh{%edge<from>}, %hh{%edge<to>});
            if !($c1 eqv $c2) {
                @span.push: %edge;
                my @c1c2 = [|$c1, |$c2].flat.unique.sort;
                for @c1c2 -> $k {
                    %hh{$k} = @c1c2;
                }
                last if %hh{%edge<from>}.elems == $n;
            }
        }

        return @span;
    }

    method !minimum-spanning-tree-prim() {
        my $start = self.vertex-list.pick;
        my %mst;
        my %visited;
        my @edges;

        %visited{$start} = True;
        @edges.push: [ $start, $_, %.adjacency-list{$start}{$_} ] for %.adjacency-list{$start}.keys;

        while @edges {
            @edges = @edges.sort({ $^a[2] <=> $^b[2] });
            my ($from, $to, $weight) = @edges.shift;

            next if %visited{$to};

            %mst{$from}{$to} = $weight;
            %mst{$to}{$from} = $weight;

            %visited{$to} = True;
            @edges.push: [ $to, $_, %.adjacency-list{$to}{$_} ] for %.adjacency-list{$to}.keys.grep: { !%visited{$_} };
        }

        return %mst;
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

    #======================================================
    # Unary Operations
    #======================================================
    # Should we have synonyms? For example:
    # method transpose(--> Graph) { return self.reverse; }

    method reverse(--> Graph) {
        if !$!directed { return self.clone; }
        my @edges = self.edges(:dataset);
        @edges = @edges.map({ <from to weight>.Array Z=> $_<to from weight>.Array })».Hash;
        my $grRes = Graph.new(@edges, :directed);
        return $grRes;
    }

    method complement(--> Graph) {
        my @vertexes = self.vertex-list;
        my @edges;
        for @vertexes -> $v1 {
            for @vertexes -> $v2 {
                if ! ( %!adjacency-list{$v1}{$v2} // False) {
                    @edges.push(%(from => $v1, to => $v2, weight => 1))
                }
            }
        }
        my $grRes = Graph.new(@edges, directed => self.directed);
        return $grRes;
    }

    #======================================================
    # Operations
    #======================================================

    #------------------------------------------------------
    #| Union with another graph.
    method union(Graph:D $g --> Graph) {
        my @vertices = (self.vertex-list (|) $g.vertex-list).keys;
        my @edges = self.edges(:dataset);

        for $g.edges(:dataset) -> %e {
            unless self.has-edge(%e<from>, %e<to>) {
                @edges .= push(%e)
            }
        }

        my $directed = $!directed || $g.directed;
        my $vertex-coordinates =
                do if self.vertex-coordinates ~~ Map:D && $g.vertex-coordinates ~~ Map:D {
                    $vertex-coordinates = [|self.vertex-coordinates, |$g.vertex-coordinates].Hash
                } else { Whatever }
        return Graph.new(@vertices, @edges, :$directed, :$vertex-coordinates);
    }

    #------------------------------------------------------
    #| Intersection with another graph.
    method intersection(Graph:D $g --> Graph) {
        my @vertices = (self.vertex-list (|) $g.vertex-list).keys;
        my @edges;

        for $g.edges(:dataset) -> %e {
            if self.has-edge(%e<from>, %e<to>) {
                @edges .= push(%e)
            }
        }

        my $directed = $!directed || $g.directed;
        my $vertex-coordinates =
                do if self.vertex-coordinates ~~ Map:D && $g.vertex-coordinates ~~ Map:D {
                    $vertex-coordinates = [|self.vertex-coordinates, |$g.vertex-coordinates].Hash
                } else { Whatever }
        return Graph.new(@vertices, @edges, :$directed, :$vertex-coordinates);
    }

    #------------------------------------------------------
    #| Difference with another graph.
    method difference(Graph:D $g --> Graph) {
        my @vertices = (self.vertex-list (|) $g.vertex-list).keys;
        my @edges;

        for self.edges(:dataset) -> %e {
            unless $g.has-edge(%e<from>, %e<to>) {
                @edges .= push(%e)
            }
        }

        my $directed = $!directed || $g.directed;
        my $vertex-coordinates =
                do if self.vertex-coordinates ~~ Map:D && $g.vertex-coordinates ~~ Map:D {
                    $vertex-coordinates = [|self.vertex-coordinates, |$g.vertex-coordinates].Hash
                } else { Whatever }
        return Graph.new(@vertices, @edges, :$directed, :$vertex-coordinates);
    }

    #======================================================
    # Subgraph
    #======================================================
    multi method subgraph($subvertex where $subvertex ~~ Str:D | Int:D) {
        return self.subgraph([$subvertex.Str,]);
    }

    multi method subgraph(@subvertexes where @subvertexes.all ~~ Str:D) {
        my @edges = self.edges(:dataset);
        @edges .= grep({ $_<from> ∈ @subvertexes || $_<to> ∈ @subvertexes });
        my %vertex-coordinates =
                $!vertex-coordinates ~~ Map:D ?? $!vertex-coordinates.grep({ $_.key ∈ @subvertexes }) !! Whatever;
        return Graph.new(@edges, :$!directed, :%vertex-coordinates);
    }

    multi method subgraph(@subedges where @subedges.all ~~ Pair:D) {
        my @edges = self.edges(:!dataset);
        my $set = @subedges».Str;
        if $!directed {
            @edges .= grep({ $_.Str ∈ $set });
        } else {
            @edges .= grep({ ($_.Str ∈ $set) || (Pair.new($_.value, $_.key).Str ∈ $set)});
        }
        my @subvertexes = [|@edges».key, |@edges».value].unique;
        my @edgesNew = self.edges(:!dataset).grep({ $_.key ∈ @subvertexes && $_.value ∈ @subvertexes });
        my %vertex-coordinates =
                $!vertex-coordinates ~~ Map:D ?? $!vertex-coordinates.grep({ $_.key ∈ @subvertexes }) !! Whatever;
        return Graph.new(@edgesNew, :$!directed, :%vertex-coordinates);
    }

    multi method subgraph(@subedges where @subedges.all ~~ Map:D) {
        my @edges = @subedges.grep({ $_<from>.defined && $_<to>.defined });
        if @subedges && !@edges {
            note 'The given Positional of Maps did not have graph edge records with keys "from" and "to".';
        }
        @edges .= map({ $_<from> => $_<to> });
        return self.subgraph(@edges);
    }

    #======================================================
    # NeighborhoodGraph
    #======================================================
    multi method neighborhood-graph(Str:D $v, UInt:D :d(:$max-path-length) = 1) {
        return self.neighborhood-graph([$v, ], :$max-path-length);
    }

    multi method neighborhood-graph(Graph $g, UInt:D $d = 1) {
        return self.neighborhood-graph($g.vertex-list, $d);
    }

    multi method neighborhood-graph(@spec, UInt:D :d(:$max-path-length) = 1) {
        if !$!directed {
            return Graph.new(self!neighborhood-graph-edges(@spec, :$max-path-length));
        } else {
            # This might not be very efficient for large graphs,
            # but it is obviously correct and descriptive.
            my $g = Graph.new(self, :!directed);
            my $g2 = $g.neighborhood-graph(@spec, :$max-path-length);
            my @edges = $g2.edges(:dataset).map({
                if %!adjacency-list{$_<from>}{$_<to>}:exists {
                    $_
                } elsif %!adjacency-list{$_<to>}{$_<from>}:exists {
                    %(from => $_<to>, to => $_<from>, weight => $_<weight>)
                } else {
                    Empty
                }
            });
            return Graph.new(@edges, :directed);
        }
    }

    #======================================================
    # Highlight spec
    #======================================================
    # Graph is not defined in the role file, hence this multi method definition.
    multi method process-highlight-spec(Graph:D $g, Bool :directed(:$directed-edges) = False) {
        # Why the following line does not work?
        # return $g.process-highlight-spec(:$directed-edges);
        return self.process-highlight-spec([|$g.vertex-list, |$g.edges], :directed-edges);
    }
}