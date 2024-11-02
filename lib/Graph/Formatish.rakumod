use v6.d;

role Graph::Formatish {

    #------------------------------------------------------
    sub to-wl-value($x) {
        return do given $x {
            when ($_ ~~ Str:D) && ($_ ~~ / ^ '`' .* '`' $ /) { $_.substr(1, $_.chars - 2) }
            when ($_ ~~ Str:D) && ($_ ~~ / ^ '${' .* '}' $ /) { $_.substr(1, $_.chars - 3) }
            when Str:D { '"' ~ $_ ~ '"' }
            default { $_.Str }
        };
    }

    method wl(*%args) {
        my @dsEdges = self.edges(:dataset);
        my $edges = @dsEdges.map({ "\"{ $_<from> }\" -> \"{ $_<to> }\"" }).join(', ');
        my $weights = @dsEdges.map({ $_<weight>.Str }).join(', ');

        my $args = '';
        if %args {
            $args = ', ' ~ %args.map({ "{$_.key} -> { to-wl-value($_.value) }" }).join(', ');
        }

        my $vertexes = '"' ~ self.vertex-list.join('", "') ~ '"';

        return "Graph[\{$vertexes\}, \{$edges\}, EdgeWeight -> \{$weights\}, DirectedEdges -> { self.directed }{ $args }]";
    }

    #------------------------------------------------------
    method mermaid(Str:D :d(:$direction) = 'LR', :$weights is copy = Whatever, Bool:D :f(:fence(:code-fence(:$code-block))) = False ) {

        my @dsEdges = self.edges(:dataset);

        my $arrow = self.directed ?? '-->' !! '---';

        my $allOne = [&&] @dsEdges.map({ $_<weight> == 1 });

        my $edges =
                do if $weights.isa(Whatever) && $allOne || ($weights ~~ Bool:D) && !$weights {
                    @dsEdges.map({ "{ $_<from> } $arrow { $_<to> }" }).join("\n");
                } else {
                    @dsEdges.map({ "{ $_<from> } $arrow |{ $_<weight>.Str }|{ $_<to> }" }).join("\n");
                }

        my $res = "graph $direction\n$edges";
        return $code-block ?? "```mermaid\n{$res}\n```" !! $res;
    }

    #------------------------------------------------------
    method dot(:$weights is copy = Whatever) {

        my @dsEdges = self.edges(:dataset);

        my $arrow = self.directed ?? '->' !! '--';

        my $allOne = [&&] @dsEdges.map({ $_<weight> == 1 });

        my $edges =
                do if $weights.isa(Whatever) && $allOne || ($weights ~~ Bool:D) && !$weights {
                    @dsEdges.map({ "\"{ $_<from> }\" $arrow \"{ $_<to> }\"" }).join("\n");
                } else {
                    @dsEdges.map({ "\"{ $_<from> }\" $arrow \"{ $_<to> }\" [weight={$_<weight>.Str }, label={$_<weight>.Str }]" }).join("\n");
                }

        my $vertexes = '"' ~ self.vertex-list.join('"; "') ~ '";';

        "{self.directed ?? 'digraph' !! 'graph'} \{\n$vertexes\n$edges\n\}";
    }

    #------------------------------------------------------
    method graphml() {
        my $xml = qq:to/END/;
        <?xml version="1.0" encoding="UTF-8"?>
        <graphml xmlns="http://graphml.graphdrawing.org/xmlns"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xsi:schemaLocation="http://graphml.graphdrawing.org/xmlns
                                 http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd">
        <graph edgedefault="{ self.directed ?? 'directed' !! 'undirected' }">
        END

        for %.adjacency-list.kv -> $from, %to {
            $xml ~= qq:to/END/;
            <node id="{ $from }"/>
            END

            for %to.kv -> $to, $weight {
                $xml ~= qq:to/END/;
                <node id="{ $to }"/>
                <edge source="{ $from }" target="{ $to }" weight="{ $weight }"/>
                END
            }
        }

        $xml ~= qq:to/END/;
        </graph>
        </graphml>
        END

        return $xml;
    }
}