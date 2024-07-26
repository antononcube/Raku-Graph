use v6.d;

role Graph::Neighborhoodish {
    method !neighborhood-graph-edges(@spec, UInt:D :d(:$max-path-length) = 1) {
        my @vertices = @spec.grep({ $_ ~~ Str:D });
        my @edges = @spec.grep({  $_ ~~ Pair:D });

        @edges.map({ @vertices.append([$_.key, $_.tail ])});
        @vertices .= unique;

        # Instead of this loop we can use self.find-path or self!dfs
        my %neighborhood;
        #my @lastLevelVertices;
        for @vertices -> $vertex {
            %neighborhood{$vertex} = gather {
                my @queue = [$vertex,];
                my %visited;
                my $current-length = 0;
                while @queue && $current-length ≤ $max-path-length {
                    my @next-queue;
                    for @queue -> $v {
                        next if %visited{$v}:exists;
                        %visited{$v} = True;
                        take $v;
                        #@lastLevelVertices.push($v) if $current-length == $max-path-length;
                        if %.adjacency-list{$v}:exists {
                            for %.adjacency-list{$v}.keys -> $neighbor {
                                @next-queue.push($neighbor) unless %visited{$neighbor}:exists;
                            }
                        }
                    }
                    @queue = @next-queue;
                    $current-length++;
                }
            }.cache
        }

        # Make the Cartesian product of the gathered vertices and get all edges that correspond to them
        @vertices = %neighborhood.values.map(*.Slip).unique;

        @edges = (@vertices X @vertices).map({
            %.adjacency-list{$_.head}{$_.tail}:exists ?? %(from => $_.head, to => $_.tail, weight => %.adjacency-list{$_.head}{$_.tail}) !! Empty
        });
        # Note that is likely too slow -- known edges are also tested.
        # It is obviously correct though, and it should be benchmarked before optimizing.

        # Result
        return @edges;
    }
}