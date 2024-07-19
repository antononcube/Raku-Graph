use v6.d;

role Graph::Bipartitish {
    method bipartite-coloring(--> Map) {
        my %color;
        my @queue;

        for %.adjacency-list.keys -> $vertex {
            next if %color{$vertex}:exists;
            %color{$vertex} = 0;
            @queue.push($vertex);

            while @queue {
                my $current = @queue.shift;
                my $current-color = %color{$current};

                for %.adjacency-list{$current}.keys -> $neighbor {
                    if %color{$neighbor}:exists {
                        return %() if %color{$neighbor} == $current-color;
                    } else {
                        %color{$neighbor} = 1 - $current-color;
                        @queue.push($neighbor);
                    }
                }
            }
        }

        return %color;
    }

    #----------------------------------------------------------------
    method is-bipartite(--> Bool) {
        my %color = self.bipartite-coloring;
        return so %color;
    }

    #----------------------------------------------------------------
    method hungarian-algorithm() {

        my %colors = self.bipartite-coloring;
        if %colors.elems == 0 {
            die "The graph is not bipartite.";
        }

        my @left = %colors.grep({ $_.value == 0 })».key;
        my @right = %colors.grep({ $_.value == 1 })».key;


        my $dummy-prefix = "⎡⎡⎡DUMMY_" ~ ('a'..'z').pick(12).join;
        if @right.elems < @left.elems {
            @right = @right.append((^(@left.elems - @right.elems)).map({ $dummy-prefix ~ "_RIGHT_" ~ $_ }))
        } elsif @left.elems < @right.elems {
            @left = @left.append((^(@right.elems - @left.elems)).map({ $dummy-prefix ~ "_LEFT_" ~ $_ }))
        }

        my %cost;

        for @left -> $u {
            for @right -> $v {
                %cost{$u}{$v} = %.adjacency-list{$u}{$v} // 0;
            }
        }

        my %lx = @left.map({ $_ => %cost{$_}.values.max // 0 });
        my %ly = @right.map({ $_ => 0 });
        my %match;
        my %rev-match;

        sub dfs($u, %visited) {
            %visited{$u} = True;
            for @right -> $v {
                if %visited{$v}:exists {
                    next;
                }
                my $slack = %lx{$u} + %ly{$v} - %cost{$u}{$v};
                if $slack == 0 {
                    %visited{$v} = True;
                    if !%match{$v} || dfs(%match{$v}, %visited) {
                        %match{$v} = $u;
                        %rev-match{$u} = $v;
                        return True;
                    }
                }
            }
            return False;
        }

        for @left -> $u {
            loop {
                my %visited;
                if dfs($u, %visited) {
                    last;
                }
                my $delta = Inf;
                for @left -> $u {
                    if %visited{$u} {
                        for @right -> $v {
                            unless %visited{$v} {
                                $delta = min($delta, %lx{$u} + %ly{$v} - %cost{$u}{$v});
                            }
                        }
                    }
                }
                for @left -> $u {
                    if %visited{$u} {
                        %lx{$u} -= $delta;
                    }
                }
                for @right -> $v {
                    if %visited{$v} {
                        %ly{$v} += $delta;
                    }
                }
            }
        }

        return %rev-match.grep({ !$_.key.starts-with($dummy-prefix) && !$_.value.starts-with($dummy-prefix) }).Hash;
    }
}