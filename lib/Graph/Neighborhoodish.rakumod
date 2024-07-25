use v6.d;

role Graph::Neighborhoodish {
    method !neighborhood-graph-edges(@spec, UInt:D :d(:$max-path-length) = 1) {
        my @vertices = @spec.grep({ $_ ~~ Str:D });
        my @edges = @spec.grep({  $_ ~~ Pair:D });

        @edges.map({ @vertices.append([$_.key, $_.tail ])});
        @vertices .= unique;

        my %neighborhood;
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

        # The loops above put the $vertex in %neighborhood{$vertex}.
        # The graph might or might not have the $vertex loop edge.
        # Hence the the %.adjacency-list{$_.key}{$v}:exist check below.
        # For all other vertices in %neighborhood{$vertex} the check %.adjacency-list{$_.key}{$v}:exist should be true.
        @edges = %neighborhood.map({
            $_.value.map( -> $v {
                %.adjacency-list{$_.key}{$v}:exists ?? %(from => $_.key, to => $v, weight => %.adjacency-list{$_.key}{$v}) !! Empty
            }) }).map(*.Slip);

        # Make the Cartesian product of the gathered vertices and get all edges that correspond to them
        @vertices = %neighborhood.values.map(*.Slip).unique;

        my @closure = (@vertices X @vertices).map({
            %.adjacency-list{$_.head}{$_.tail}:exists ?? %(from => $_.head, to => $_.tail, weight => %.adjacency-list{$_.head}{$_.tail}) !! Empty
        });

        @edges = @edges.append(@closure);

        # Result
        return @edges;
    }
}