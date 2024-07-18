use v6.d;

role Graph::Tourish {
    method find-postman-tour() {
        sub find-odd-degree-vertices(%adj-list) {
            %adj-list.keys.grep({ %adj-list{$_}.keys.elems % 2 });
        }

        sub find-minimum-weight-matching(@odd-vertices, %adj-list) {
            my @extEdges;
            for @odd-vertices.combinations(2) -> ($v1, $v2) {
                my @path = self.find-shortest-path($v1, $v2);
                my $weight = @path.rotor(2 => -1).map({ self.adjacency-list{$_.head}{$_.tail} }).sum;
                @extEdges.push: ($v1, $v2, $weight);
            }
            @extEdges = @extEdges.sort({ $^a[2] <=> $^b[2] });
            my %matching;
            for @extEdges -> $edge {
                my ($v1, $v2, $w) = $edge;
                unless %matching{$v1} || %matching{$v2} {
                    %matching{$v1} = $v2;
                    %matching{$v2} = $v1;
                }
            }
            %matching;
        }

        sub eulerian-circuit(%adj-list) {
            my @stack = %adj-list.keys.head;
            my @circuit;
            while @stack {
                my $v = @stack.tail;
                if %adj-list{$v}.elems {
                    my $u = %adj-list{$v}.keys.head;
                    @stack.push: $u;
                    %adj-list{$v}{$u}:delete;
                    %adj-list{$u}{$v}:delete;
                } else {
                    @circuit.push: @stack.pop;
                }
            }
            @circuit;
        }

        my %adj-list = %.adjacency-list.clone;
        %adj-list = %adj-list.map({ $_.key => $_.value.clone });

        my @odd-vertices = find-odd-degree-vertices(%adj-list);
        if @odd-vertices > 2 {
            die "The method find-postman-tour only works on Eulerian graphs.";
        }

        my %matching;
        if @odd-vertices.elems {
            %matching = find-minimum-weight-matching(@odd-vertices, %adj-list);
            for %matching.kv -> $v1, $v2 {
                %adj-list{$v1}{$v2} = %adj-list{$v2}{$v1} = 0;
            }
        }

        my @res = eulerian-circuit(%adj-list);

        @res = @res.rotor(2 => -1).map({
            if (%matching{$_.head}:exists) && %matching{$_.head} eq $_.tail {
                self.find-shortest-path($_.head, $_.tail).head(*-1)
            } else {
                $_.head
            }
        }).flat.Array.append(@res.tail);

        return @res;
    }
}