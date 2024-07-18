use v6.d;

role Graph::Bipartitish {
    method is-bipartite(--> Bool) {
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
                        return False if %color{$neighbor} == $current-color;
                    } else {
                        %color{$neighbor} = 1 - $current-color;
                        @queue.push($neighbor);
                    }
                }
            }
        }

        return True;
    }
}