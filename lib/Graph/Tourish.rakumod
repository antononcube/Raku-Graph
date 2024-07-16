use v6.d;

role Graph::Tourish {
    method find-postman-tour() {
        sub find-odd-degree-vertices(%adj-list) {
            %adj-list.keys.grep({ %adj-list{$_}.keys.elems % 2 });
        }

        sub find-minimum-weight-matching(@odd-vertices, %adj-list) {
            my @edges;
            for @odd-vertices.combinations(2) -> ($v1, $v2) {
                @edges.push: ($v1, $v2, %adj-list{$v1}{$v2} // Inf);
            }
            @edges = @edges.grep({ $_.tail < Inf }).sort({ $^a[2] <=> $^b[2] });
            my %matching;
            for @edges -> $edge {
                my ($v1, $v2) = $edge;
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
                my $v = @stack[*-1];
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
        if @odd-vertices.elems {
            my %matching = find-minimum-weight-matching(@odd-vertices, %adj-list);
            for %matching.kv -> $v1, $v2 {
                %adj-list{$v1}{$v2} = %adj-list{$v2}{$v1} = 0;
            }
        }
        eulerian-circuit(%adj-list);
    }
}