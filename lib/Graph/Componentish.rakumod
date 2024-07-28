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

    method weakly-connected-components() {

        if $.directed {
            # Is there are faster way of doing this?
            return self.undirected-graph.weakly-connected-components;
        }

        my %visited;
        my @components;

        for %.adjacency-list.keys -> $vertex {
            unless %visited{$vertex} {
                my @stack = [$vertex, ];
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
}