use v6.d;

role Graph::Componentish {
    #======================================================
    # Connected components
    #======================================================
    method is-weakly-connected() {

        if $.directed {
            # Is there are faster way of doing this?
            return self.undirected-graph.is-weakly-connected;
        }

        my %visited;
        my @stack = %.adjacency-list.keys[0];

        while @stack {
            my $current = @stack.pop;
            unless %visited{$current} {
                %visited{$current} = True;
                @stack.append(%.adjacency-list{$current}.keys.grep({ !%visited{$_} }));
            }
        }

        return %visited.elems == %.adjacency-list.keys.elems;
    }

    #------------------------------------------------------
    method weakly-connected-components() {

        if $.directed {
            # Is there are faster way of doing this?
            return self.undirected-graph.weakly-connected-components;
        }

        my %visited;
        my @components;

        for %.adjacency-list.keys -> $vertex {
            unless %visited{$vertex} {
                my @stack = [$vertex,];
                my @component;

                while @stack {
                    my $current = @stack.pop;
                    unless %visited{$current} {
                        %visited{$current} = True;
                        @component.push($current);
                        @stack.append(%.adjacency-list{$current}.keys.grep({ !%visited{$_} }));
                    }
                }
                @components.push(@component);
            }
        }

        return @components.sort(*.elems).reverse.Array;
    }

    #------------------------------------------------------
    # See https://en.wikipedia.org/wiki/Tarjan%27s_strongly_connected_components_algorithm
    method !tarjan-scc(--> List) {
        my %index-of;
        my %lowlink-of;
        my @stack;
        my %on-stack;
        my $index = 0;
        my @sccs;

        sub strongconnect($v) {
            %index-of{$v} = $index;
            %lowlink-of{$v} = $index;
            $index++;
            @stack.push($v);
            %on-stack{$v} = True;

            for %.adjacency-list{$v}.keys -> $w {
                if %index-of{$w}:!exists {
                    # Target $w has not yet been visited; recurse on it
                    strongconnect($w);
                    %lowlink-of{$v} = min(%lowlink-of{$v}, %lowlink-of{$w});
                } elsif %on-stack{$w} {
                    # Successor $w is in stack %on-stack and hence in the current SCC
                    # If $w is not on stack, then (v -> w) is an edge pointing to an SCC already found and must be ignored
                    # See below regarding the next line
                    %lowlink-of{$v} = min(%lowlink-of{$v}, %index-of{$w});
                }
            }

            # If $v is a root node, pop the stack and generate an SCC
            if %lowlink-of{$v} == %index-of{$v} {
                my @scc;
                my $w;
                # Start a new strongly connected component
                repeat {
                    $w = @stack.pop;
                    %on-stack{$w} = False;
                    # Add $w to current strongly connected component
                    @scc.push($w);
                } until $w eq $v;

                # Add found component
                @sccs.push(@scc);
            }
        }

        # Iterate over all vertices
        for self.vertex-list -> $v {
            strongconnect($v) unless %index-of{$v}:exists;
        }

        # Result
        # Give largest components first.
        return @sccs».List.sort(-*.elems).List;
    }

    #------------------------------------------------------
    method connected-components(:$method is copy = Whatever) {

        if $method.isa(Whatever) || $method.isa(WhateverCode) { $method = 'tarjan' }
        die 'The value of $method is expected to be a string or Whatever.'
        unless $method ~~ Str:D;

        return do given $method.lc {
            when 'tarjan' { self!tarjan-scc }
            default {
                die 'Unknown method.'
            }
        }
    }

    #------------------------------------------------------
    method is-connected() {
        return self.connected-components.elems == 1;
    }

    #------------------------------------------------------
    method topological-sort() {
        if !self.directed { return Empty }
        my %candidates = self.vertex-list.map({ $_ => self.vertex-in-degree($_) }).grep({ $_.value == 0 });
        if ! %candidates { return Empty }
        my @sccs = self.connected-components(method => 'tarjan').reverse;
        return @sccs.map(*.Slip).List;
    }
}