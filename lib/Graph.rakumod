use v6.d;

use BinaryHeap;
use Data::TypeSystem;
use Graph::Bipartitish;
use Graph::Componentish;
use Graph::Formatish;
use Graph::MinCuttish;
use Graph::Neighborhoodish;
use Graph::Tourish;

class Graph
        does Graph::Bipartitish
        does Graph::Componentish
        does Graph::Formatish
        does Graph::MinCuttish
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

    multi method new(%edges, Bool:D :d(:directed-edges(:$directed)) = False, :$vertex-coordinates = Whatever) {
        self.bless(adjacency-list => %(), :$directed, edges => %edges.pairs, :$vertex-coordinates);
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

    #------------------------------------------------------
    #| Yields True if the graph object is a complete graph, and False otherwise.
    multi method is-complete(--> Bool:D) {
        return False if %!adjacency-list.elems == 0 || %!adjacency-list.elems < self.vertex-count;
        # No using junction.
        # This algebraic check assumes that %!adjacency-list does not have "outsider" vertexes.
        my @counts = %!adjacency-list.map( -> $r { $r.value.grep({ $_.key ne $r.key }).elems });
        return @counts.min == self.vertex-count - 1 == @counts.max;
    }

    #| Yields True if the subgraph induced by $v is a complete graph, and False otherwise.
    #| C<:$v> - Spec, vertex(es) or graph.
    multi method is-complete($v --> Bool:D) {
        return self.subgraph($v).is-complete;
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
    #| Add a single edge.
    #| C<$from> -- From vertex.
    #| C<$from> -- To vertex.
    #| C<$weight> -- Edge weight.
    #| C<:d(:$directed)> -- Is the edge directed or not.
    multi method edge-add(Str:D $from, Str:D $to, Numeric:D $weight = 1, Bool:D :d(:$directed) = False) {
        %!adjacency-list{$from}{$to} = $weight;

        if !$directed {
            %!adjacency-list{$to}{$from} = $weight;
        }
        if $directed { $!directed = True; }
        return self;
    }

    #| Add a list of edges.
    #| C<@edges> -- List of edges. Both Map and Pair objects can be used.
    #| C<:d(:$directed)> -- Are the edge directed or not.
    multi method edge-add(@edges, Bool:D :d(:$directed) = False) {
        if is-reshapable(@edges, iterable-type => Positional, record-type => Map) {
            for @edges -> %edge {
                self.edge-add(%edge<from>, %edge<to>, %edge<weight> // 1, :$directed);
            }
        } elsif is-reshapable(@edges, iterable-type => Positional, record-type => Positional) {
            for @edges -> @edge {
                if !(@edge.elems ≥ 2 && @edge[^2].all ~~ Str:D) {
                    die "When the edges are specified as a Positional of Positionals " ~
                            "then edge record is expected to have two or three elements. " ~
                            "The first two record elements are expected to be strings; the third, if present, a number.";
                }
                self.edge-add(@edge[0], @edge[1], @edge[3] // 1, :$directed);
            }
        } elsif @edges.all ~~ Pair:D {
            return self.add-edges(@edges».kv».List.List, :$directed);
        } else {
            die "The first argument is expected to be a Positional of Maps or a Positional of Positionals.";
        }
        return self;
    }

    #| Partial synonym of edge-add, adding a list of edges.
    method add-edges(@edges, Bool:D :d(:$directed) = False) {
        return self.edge-add(@edges, :$directed);
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
    # Vertex replacing
    #======================================================
    multi method vertex-replace(Pair:D $p, Bool:D :$clone = True) {
        return self.vertex-replace(%($p,), :$clone);
    }

    multi method vertex-replace(%rules, Bool:D :$clone = True) {
        my @edges = self.edges(:dataset).map({ %(
            from => %rules{$_<from>} // $_<from>,
            to => %rules{$_<to>} // $_<to>,
            weight => $_<weight>,
        ) });

        my @vertexes = self.vertex-list.map({ %rules{$_} // $_ }).unique;

        my $obj = Graph.new(@vertexes, @edges, :$!directed, :$!vertex-coordinates);

        # If vertex-coordinates are present.
        if $obj.vertex-coordinates ~~ Map:D {
            $obj.vertex-coordinates = $obj.vertex-coordinates.map({ (%rules{$_.key} // $_.key) => $_.value }).Hash;
        }

        return $obj if $clone;

        self.adjacency-list = $obj.adjacency-list;
        self.vertex-coordinates = $obj.vertex-coordinates;

        return self;
    }

    #======================================================
    # Vertex contracting
    #======================================================
    multi method vertex-contract(@vs where @vs.all ~~ Str:D, Bool:D :$clone = True) {
        my $obj = $clone ?? self.clone !! self;
        if @vs.elems < 2 { return $obj }

        # This is twice as long as needed for undirected graphs.
        my @edges = (@vs X=> @vs);

        $obj.edge-delete(@edges);

        my %rules = @vs.tail(*-1) X=> @vs.head;
        return $obj.vertex-replace(%rules, :!clone);
    }

    multi method vertex-contract(@vs where @vs.all ~~ (Array:D | List:D | Seq:D), Bool:D :$clone = True) {
        my $obj = $clone ?? self.clone !! self;
        for @vs -> @v {
            $obj = $obj.vertex-contract(@v, :!clone)
        }
        return $obj;
    }

    #======================================================
    # Equivalence
    #======================================================
    method eqv(Graph:D $g) {
        my $same-lvl1 = %!adjacency-list.keys.sort eqv $g.adjacency-list.keys.sort;
        return False unless $same-lvl1;

        for %!adjacency-list.keys -> $v {
            return False unless %!adjacency-list{$v} eqv $g.adjacency-list{$v}
        }
        return True;
    }

    #======================================================
    # Properties
    #======================================================
    #| Edges of the graph object.
    #| C<:$dataset> -- whether the result to be a dataset or a list of pairs.
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
    #| Gives the list of edges for the graph object.
    method edge-list(Bool:D :$dataset = False) {
        return self.edges(:!dataset);
    }

    #------------------------------------------------------
    #| Gives a count of the number of edges in the graph object.
    method edge-count(--> Int) {
        if $!directed {
            # Assuming this is faster.
            return %!adjacency-list.map(*.value.elems).sum;
        } else {
            return self.edges.elems;
        }
    }

    #------------------------------------------------------
    #| Gives the list of vertices for the graph object.
    method vertex-list() {
        my @res = |%!adjacency-list.map({ $_.value.keys }).map(*.Slip).unique;
        @res .= append(%!adjacency-list.keys);

        return @res.unique.sort.List;
    }

    #------------------------------------------------------
    #| Gives a count of the number of vertices in the graph object.
    method vertex-count(--> Int) {
        return self.vertex-list().elems;
    }

    #------------------------------------------------------
    #| Gives the list of vertex in-degrees for all vertices in the graph object.
    multi method vertex-in-degree(Bool:D :p(:$pairs) = False) {
        return do if $pairs {
            self.vertex-list.map({ $_ => self.vertex-in-degree($_) })
        } else {
            self.vertex-list.map({ self.vertex-in-degree($_) })
        }
    }

    #| Gives the vertex in-degree for the vertex argument
    multi method vertex-in-degree(Str:D $v, Bool:D :p(:$pairs) = False) {
        return do if $pairs {
            $v => self.vertex-degree($v, :!pairs)
        } else {
            if $!directed {
                self.adjacency-list{*;$v}.flat.grep(*.defined).elems
            } else {
                self.vertex-degree($v)
            }
        }
    }

    #------------------------------------------------------
    #| Gives the list of vertex out-degrees for all vertices in the graph object.
    multi method vertex-out-degree(Bool:D :p(:$pairs) = False) {
        return do if $pairs {
            self.vertex-list.map({ $_ => self.vertex-out-degree($_) })
        } else {
            self.vertex-list.map({ self.vertex-out-degree($_) })
        }
    }

    #| Gives the vertex out-degree for the vertex argument
    multi method vertex-out-degree(Str:D $v, Bool:D :p(:$pairs) = False) {
        return do if $pairs {
            $v => self.vertex-degree($v, :!pairs)
        } else {
            if $!directed {
                self.adjacency-list{$v}.elems // 0
            } else {
                self.vertex-degree($v);
            }
        }
    }

    #------------------------------------------------------
    #| Gives the list of vertex degrees for all vertices in the graph object.
    multi method vertex-degree(Bool:D :p(:$pairs) = False) {
        return do if $pairs {
            self.vertex-list.map({ $_ => self.vertex-degree($_) })
        } else {
            self.vertex-list.map({ self.vertex-degree($_) })
        }
    }

    #| Gives the vertex degree for the vertex argument.
    multi method vertex-degree(Str:D $v, Bool:D :p(:$pairs) = False) {
        return do if $pairs {
            $v => self.vertex-degree($v, :!pairs)
        } else {
            if $!directed {
                self.vertex-out-degree($v) - self.vertex-in-degree($v)
            } else {
                self.adjacency-list{$v}.elems // 0
            }
        }
    }

    #======================================================
    # Basic conversions
    #======================================================
    #| Gives an undirected graph for directed graph object.
    method undirected-graph() {
        return self.clone(:!directed);
    }

    #| Gives a directed graph for undirected graph object.
    #| C<:$method> -- Conversion method "Acyclic", "Random", or Whatever.
    method directed-graph(:m(:$method) = Whatever, Numeric:D :threshold(:$flip-threshold) = 0.5) {
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
                    Graph.new(@edges, :$!vertex-coordinates, :directed)
                }
                when $_ ~~ Str:D && $_.lc eq 'random' {
                    my @edges = self.edges(:dataset);
                    @edges = @edges.map({ rand ≥ $flip-threshold ?? $_ !! %( from => $_<to>, to => $_<from>, weight => $_<weight>) });
                    Graph.new(@edges, :$!vertex-coordinates, :directed)
                }
                default {
                    die 'The value of $method is expected to be "Acyclic", "Random", or Whatever.';
                }
            }
        }
    }

    method index-graph(Int:D $r = 0, :with(:&as) = WhateverCode, :$prefix = '') {
        my %index;
        my $index = $r;

        my @vs = self.vertex-list;
        @vs .= sort(&as) unless &as.isa(WhateverCode);

        for @vs -> $vertex {
            %index{$vertex} = $prefix ~ $index++;
        }

        my %new-adjacency-list;
        for self.edges(:dataset) -> %e {
            %new-adjacency-list{%index{%e<from>}}{%index{%e<to>}} = %e<weight>;
            if !self.directed {
                %new-adjacency-list{%index{%e<to>}}{%index{%e<from>}} = %e<weight>;
            }
        }
        my $vertex-coordinates = do if self.vertex-coordinates ~~ Map:D {
            self.vertex-coordinates.map({ %index{$_.key} => $_.value }).Hash
        } else { Whatever }

        return Graph.bless(:adjacency-list(%new-adjacency-list), :directed(self.directed), :$vertex-coordinates);
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

    #| Gives the adjacency matrix for the graph object.
    #| C<:$weighted> -- Whether to give weighted adjacency matrix or not.
    method adjacency-matrix(Bool:D :w(:$weighted) = False) {
        my @matrix;
        for self.vertex-list -> $i {
            my @row;
            for self.vertex-list -> $j {
                my $v = do if $weighted {
                    %!adjacency-list{$i}{$j} // 0;
                } else {
                    %!adjacency-list{$i}{$j} // False ?? 1 !! 0;
                }
                @row.push($v)
            }
            @matrix.push(@row);
        }
        return @matrix;
    }

    #| Synonym of adjacency-matrix.
    method Array() {
        return self.adjacency-matrix(:!weighted);
    }

    #| Gives the incidence matrix for the graph object.
    method incidence-matrix() {
        my @matrix;
        for self.vertex-list -> $i {
            my @row;
            for self.edge-list -> $j {
                if $!directed {
                    @row.push($i eq $j.key ?? 1 !! ($i eq $j.tail ?? -1 !! 0))
                } else {
                    @row.push($i ∈ $j.kv ?? 1 !! 0)
                }
            }
            @matrix.push(@row);
        }
        return @matrix;
    }

    #======================================================
    # Shortest paths algorithms
    #======================================================
    #| Find shortest path.
    #| C<$start> -- Start vertex.
    #| C<$end> -- End vertex.
    #| C<:$method> -- Method, one of "A-star", "Dijkstra", or Whatever.
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
    #| Find paths
    #| C<$s> -- Start vertex.
    #| C<$t> -- End vertex.
    #| C<:$min-length> -- Minimum path length.
    #| C<:$max-length> -- Maximum path length.
    #| C<:$count> -- Number of paths to find.
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
    #| Find Hamiltonian path.
    multi method find-hamiltonian-path() {
        self!hamiltonian-path-backtracking(:warnsdorf-rule);
    }

    #| Find Hamiltonian path.
    #| C<$s> -- Start vertex.
    #| C<$t> -- End vertex.
    #| C<:$method> -- Method, one of "backtracking", "random", or Whatever.
    #| C<*%args> -- Options for the different algorithm implementations.
    multi method find-hamiltonian-path(Str:D $s, $t, :$method = Whatever, *%args --> Array) {
        my @res = do given $method {
            when Whatever {
                self!hamiltonian-path-backtracking-from-to($s, $t, |%args)
            }
            when ($_ ~~ Str:D) && $_.lc ∈ <backtracking backtrack bt> {
                self!hamiltonian-path-backtracking-from-to($s, $t, |%args)
            }
            when ($_ ~~ Str:D) && $_.lc ∈ <angluin-valiant av random> {
                if $t.isa(Whatever) {
                    my $t2 = '⎡⎡⎡⎡Whatever-' ~ 1e20.rand ~ '⎦⎦⎦⎦';
                    my $g2 = self.clone;
                    $g2.edge-add($t2 X=> self.vertex-list);
                    my @path = $g2!hamiltonian-path-angluin-valiant($s, $t2, |%args);
                    @path ?? @path.head(*-1) !! []
                } else {
                    self!hamiltonian-path-angluin-valiant($s, $t, |%args)
                }
            }
            default {
                die 'Unknown method. The value of $method is expected to be one of "backtracking" or Whatever.'
            }
        }
        return @res;
    }

    #------------------------------------------------------
    method !hamiltonian-path-backtracking(Bool:D :warnsdorf(:$warnsdorf-rule) = True) {
        my @vertices = %!adjacency-list.keys;

        my @path;
        for @vertices -> $start {
            @path = self!hamiltonian-path-backtracking-from-to($start, Whatever, :$warnsdorf-rule);
            last if @path;
        }

        return @path;
    }

    #------------------------------------------------------
    method !hamiltonian-path-backtracking-from-to(Str:D $s, $t = Whatever, Bool:D :warnsdorf(:$warnsdorf-rule) = True) {
        my %visited;
        my @path;

        sub hamiltonian-path(Str $current) {
            return True if @path.elems == %!adjacency-list.keys.elems && ($t.isa(Whatever) || $current eq $t);

            my @nns = do if $warnsdorf-rule {
                %!adjacency-list{@path.tail}.keys.grep({ !%visited{$_} }).sort({ %!adjacency-list{$_}.keys.grep({ !%visited{$_} }).elems })
            } else {
                %!adjacency-list{@path.tail}.keys.grep({ !%visited{$_} })
            }

            for @nns -> $neighbor {
                %visited{$neighbor} = True;
                @path.push($neighbor);
                return True if hamiltonian-path($neighbor);
                @path.pop;
                %visited{$neighbor} = False;
            }
            return False;
        }

        %visited{$s} = True;
        @path.push($s);
        return hamiltonian-path($s) ?? @path !! [];
    }

    #------------------------------------------------------
    method !hamiltonian-path-angluin-valiant(Str $s, Str $t,
                                             :n(:$max-number-of-attempts) is copy = Whatever,
                                             :d(:$degree) is copy = Whatever,
                                             :by(:pick-by(:$pick)) is copy = 'max-degree'
                                             ) {
        # Directed graphs only
        die 'The graph is expected to be undirected.' unless !self.directed;

        # Process number of attempts
        if $max-number-of-attempts.isa(Whatever) {
            $max-number-of-attempts = ceiling(5 * log(self.vertex-count) * self.vertex-count)
        }
        die 'The value of $number-of-attemps is expected to be a positve integer or Whatever.'
        unless $max-number-of-attempts ~~ Int:D && $max-number-of-attempts > 0;

        # Process number of degree
        if $degree.isa(Whatever) { $degree = 1 }
        die 'The value of $degree is expected to be a positve integer or Whatever.'
        unless $degree ~~ Int:D && $degree > 0;

        # Process next vertex pick method
        if $pick.isa(Whatever) { $pick = 'random' }
        die 'The value of $pick is expected to be one of "random", "weighted-random", "max-degree" or Whatever.'
        unless $pick ~~ Str:D && $pick ∈ <random any max max-degree weighted weighted-random random-weighted>;

        # Loop
        my @path = Empty;
        my $batch = ceiling($max-number-of-attempts / $degree);
        if $degree > 1 {
            # Parallel execution
            my @res = (^$degree).race(:$degree, batch => 1).map({
                my @p;
                for ^$batch {
                    @p = |self!hamiltonian-path-angluin-valiant-single-run($s, $t, :$pick);
                    last if @p.elems > 0;
                }
                @p
            });
            @path = @res.grep(*.elems);
            if @path { @path = |@path.head }
        } else {
            # Sequential execution
            for ^$max-number-of-attempts {
                @path = |self!hamiltonian-path-angluin-valiant-single-run($s, $t, :$pick);
                last if @path.elems > 0;
            }
        }
        return @path;
    }

    method !hamiltonian-path-angluin-valiant-single-run(Str:D $s, Str:D $t, Str:D :$pick = 'max-degree') {
        my %G = self.clone.adjacency-list;
        my $ndp = $s;
        my $P = Graph.new(:!directed);
        my @res = Empty;

        loop {
            if %G{$ndp}:!exists || %G{$ndp}.elems == 0 {
                last
            } else {
                my $v = do given $pick.lc {
                    when $_ ∈ <weighted weighted-random random-weighted> {
                        # Pick with probabilities proportional of the vertex degrees.
                        # See Warnsdorf's rule -- here it is done the opposite of that rule.
                        my @vs = %G{$ndp}.keys;
                        my @probs = %G{@vs}».elems;
                        (@vs Z=> @probs).Bag.pick
                    }
                    when $_ ∈ <max max-degree> {
                        # See Warnsdorf's rule -- here it is done the opposite of that rule.
                        my @vs = %G{$ndp}.keys;
                        my @probs = %G{@vs}».elems;
                        my $m = @probs.max;
                        (@vs Z=> @probs).grep({ $_.value == $m })».key.pick
                    }
                    default {
                        # Whatever, "random", "any"
                        %G{$ndp}.keys.pick
                    }
                }

                if %G{$ndp}{$v} // False { %G{$ndp}{$v}:delete }
                if %G{$v}{$ndp} // False { %G{$v}{$ndp}:delete }

                if $v ne $t && !$P.has-vertex($v) {
                    $P.edge-add($v, $ndp);
                    $ndp = $v;
                } elsif $v ne $s && $v ne $t && $P.has-vertex($v) {
                    my $u = $P.adjacency-list{$v}.keys.grep({ $_ ne $s && $_ ne $t }).pick;
                    $P.edge-delete($v, $u);
                    $P.edge-add($v, $ndp);
                    $ndp = $u;
                }
            }

            if $P.adjacency-list.elems ≥ self.vertex-count - 1 &&
                    (self.adjacency-list{$ndp}{$t} // False) &&
                    (%G{$ndp}{$t} // False) {
                $P.edge-add($ndp, $t);
                @res = $P.find-hamiltonian-path($s, $t, method => 'backtracking');
            }
        }
        return @res;
    }

    #======================================================
    # Find cycles
    #======================================================
    #| Finds a cycle in the graph object.
    #| C<:$min-length> -- Minimum cycle length.
    #| C<:$max-length> -- Maximum cycle length.
    #| C<:$count> -- Number of cycles to find.
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
    #| Finds a spanning tree that minimizes the total distance between the vertices of the graph object.
    #| C<:$method> -- Method, one of "Kruskal" or Whatever.
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
    #| Gives the length of the longest shortest path from the source $v to every other vertex in the graph g.
    #| C<:$v> -- Source vertex.
    method vertex-eccentricity($v --> Numeric) {
        # The distance between two vertices in a graph is the number of edges in a shortest path connecting them.
        # The eccentricity ϵ(v) of a vertex v is the greatest distance between v and any other vertex.
        my %distances = self!dijkstra-shortest-path-distances($v);
        if %distances.elems < self.vertex-count { return Inf; }
        return %distances.values.max;
    }

    #| Gives the greatest distance between any pair of vertices in the graph object.
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

    #| Gives the minimum eccentricity of the vertices in the graph object.
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

    #| Gives the set of vertices with minimum eccentricity in the graph object.
    method center(--> List) {
        my %eccentricities = %.adjacency-list.keys.map({ $_ => self.vertex-eccentricity($_) });
        my $me = %eccentricities.values.min;
        return %eccentricities.grep({ $_.value == $me })».key.sort.List;
    }

    #| Gives vertices that are maximally distant to at least one vertex in the graph object.
    method periphery(--> List) {
        my %eccentricities = %.adjacency-list.keys.map({ $_ => self.vertex-eccentricity($_) });
        my $me = %eccentricities.values.max;
        return %eccentricities.grep({ $_.value == $me })».key.sort.List;
    }

    #======================================================
    # Unary Operations
    #======================================================
    # Should we have synonyms? For example:
    # method transpose(--> Graph) { return self.reverse; }

    #| Gives the reverse graph of the directed graph object.
    method reverse(--> Graph) {
        if !$!directed { return self.clone; }
        my @edges = self.edges(:dataset);
        @edges = @edges.map({ <from to weight>.Array Z=> $_<to from weight>.Array })».Hash;
        my $grRes = Graph.new(@edges, :directed);
        return $grRes;
    }

    #| Gives the graph complement of the graph object.
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
    multi method union(Graph:D $g --> Graph) {
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

    #| Union with a list of other graphs.
    multi method union(*@gs where @gs.all ~~ Graph:D --> Graph) {
        return reduce({$^a.union($^b)}, self, |@gs);
    }

    #------------------------------------------------------
    #| Disjoint union with another graph.
    multi method disjoint-union(Graph:D $g --> Graph) {
        return self.index-graph(0).union($g.index-graph(self.vertex-count));
    }

    #| Disjoint union with a list of other graphs.
    multi method disjoint-union(*@gs where @gs.all ~~ Graph:D --> Graph) {
        return reduce({$^a.disjoint-union($^b)}, self, |@gs);
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
    #| Gives the subgraph of the graph object generated by the vertices given as first argument.
    multi method subgraph($subvertex where $subvertex ~~ Str:D | Int:D) {
        return self.subgraph([$subvertex.Str,]);
    }

    multi method subgraph(@subvertexes where @subvertexes.all ~~ Str:D) {
        my @edges = self.edges(:dataset);

        @edges .= grep({ $_<from> ∈ @subvertexes && $_<to> ∈ @subvertexes });

        my $vertex-coordinates =
                do if $!vertex-coordinates ~~ Map:D {
                    my @subvertexesNew = [|@edges.map(*<from>), |@edges.map(*<to>)].unique;
                    (@subvertexesNew Z=> $!vertex-coordinates{@subvertexesNew}).Hash
                } else { Whatever }

        return Graph.new(@edges, :$!directed, :$vertex-coordinates);
    }

    multi method subgraph(@subedges where @subedges.all ~~ Pair:D) {
        my @edges = self.edges(:!dataset);
        my $set = @subedges».Str;
        if $!directed {
            @edges .= grep({ $_.Str ∈ $set });
        } else {
            @edges .= grep({ ($_.Str ∈ $set) || (Pair.new($_.value, $_.key).Str ∈ $set)});
        }

        # This might be too permissive -- additional _directed_ edges will be picked-up.
        #my @subvertexes = [|@edges».key, |@edges».value].unique;
        #my @edgesNew = self.edges(:dataset).grep({ $_<from> ∈ @subvertexes && $_<to> ∈ @subvertexes });
        my @edgesNew = self.edges(:dataset).grep({ Pair.new($_<from>, $_<to>).Str ∈ $set });

        my $vertex-coordinates =
                do if $!vertex-coordinates ~~ Map:D {
                    my @subvertexesNew = [|@edgesNew.map(*<from>), |@edgesNew.map(*<to>)].unique;
                    (@subvertexesNew Z=> $!vertex-coordinates{@subvertexesNew}).Hash
                } else { Whatever }

        return Graph.new(@edgesNew, :$!directed, :$vertex-coordinates);
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
    #| Gives the graph neighborhood of a vertex $v in the graph object.
    #| C<$v> -- Vertex.
    multi method neighborhood-graph(Str:D $v, UInt:D :d(:$max-path-length) = 1) {
        return self.neighborhood-graph([$v, ], :$max-path-length);
    }

    #| Gives the graph neighborhood of a vertices of the $g in the graph object.
    #| C<:$g> -- Graph.
    multi method neighborhood-graph(Graph $g, UInt:D $d = 1) {
        return self.neighborhood-graph($g.vertex-list, $d);
    }

    #| Graph neighborhood for a list of vertices.
    #| C<$spec> -- Vertices
    #| C<:$max-path-length> -- Maximum distance.
    multi method neighborhood-graph(@spec, UInt:D :d(:distance(:$max-path-length)) = 1) {
        my @edges = do if $!directed {
            # This might not be very efficient for large graphs,
            # but it is obviously correct and descriptive.
            my $g = Graph.new(self, :!directed);
            my $g2 = $g.neighborhood-graph(@spec, :$max-path-length);
            $g2.edges(:dataset).map({
                if %!adjacency-list{$_<from>}{$_<to>}:exists {
                    $_
                } elsif %!adjacency-list{$_<to>}{$_<from>}:exists {
                    %(from => $_<to>, to => $_<from>, weight => $_<weight>)
                } else {
                    Empty
                }
            })
        } else {
            self!neighborhood-graph-edges(@spec, :$max-path-length)
        }

        # Get the NNs vertex coordinates if applicable
        my $vertex-coordinates =
                do if $!vertex-coordinates ~~ Map:D {
                    my @vs = [|@edges.map(*<from>), |@edges.map(*<to>)].unique;
                    (@vs Z=> $!vertex-coordinates{@vs}).Hash
                } else { Whatever }

        # Result
        return Graph.new(@edges, :$!directed, :$vertex-coordinates);
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
