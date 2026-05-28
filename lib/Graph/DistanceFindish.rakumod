use v6.d;

use BinaryHeap;
role Graph::DistanceFindish {
    #======================================================
    # Dijkstra's algorithm to all other vertexes
    #======================================================
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

    #======================================================
    # Floyd-Warshall
    #======================================================
    method !floyd-warshall() {
        my $n = self.vertex-list.elems;

        # Make the distance matrix
        my @dist;
        for self.vertex-list -> $v {
            my @row;
            for self.vertex-list -> $u {
                @row.push( $u eq $v ?? 0 !! self.adjacency-list{$u}{$v} // Inf)
            }
            @dist.push(@row)
        }

        # next[i][j] will store the next node after i on the shortest path to j
        my @next = [ [Nil xx $n] xx $n ];

        # Initialize next matrix
        for ^$n -> $i {
            for ^$n -> $j {
                @next[$i][$j] = $j if @dist[$i][$j] < Inf;
            }
        }

        # Main Floyd-Warshall loop
        for ^$n -> $k {           # intermediate vertex
            for ^$n -> $i {       # source
                for ^$n -> $j {   # destination
                    if @dist[$i][$k] < Inf && @dist[$k][$j] < Inf {
                        my $new-dist = @dist[$i][$k] + @dist[$k][$j];
                        if $new-dist < @dist[$i][$j] {
                            @dist[$i][$j] = $new-dist;
                            @next[$i][$j] = @next[$i][$k];
                        }
                    }
                }
            }
        }

        # Check for negative cycles (optional but recommended)
        for ^$n -> $i {
            if @dist[$i][$i] < 0 {
                die "Graph contains a negative-weight cycle!";
            }
        }

        return {
            :@dist,   # @dist[i][j] = shortest distance from i to j
            :@next    # for path reconstruction
        };
    }

    # Helper function to reconstruct path from u to v
    method !get-path(@next, $u, $v) {
        return [] unless @next[$u][$v].defined;

        my @path = $u;
        my $current = $u;

        while $current != $v {
            $current = @next[$current][$v];
            return [] unless $current.defined;  # no path
            @path.push($current);
        }

        return @path;
    }
}
