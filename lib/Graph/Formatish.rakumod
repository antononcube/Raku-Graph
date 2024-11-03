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


    #------------------------------------------------------
    multi method dot($weights is copy = Whatever) {
        my %core = self!dot-core(:$weights);
        return "{self.directed ?? 'digraph' !! 'graph'} \{\n{%core<vertexes>}\n{%core<edges>}\n\}";
    }

    multi method dot(
            :$weights is copy = Whatever,
            Str:D :$background = '#1F1F1F',
            Str:D :$node-shape = 'circle',
            Str:D :$node-color = 'black',
            Numeric:D :$node-size = 0.1,
            Str:D :$node-fill-color = 'steelblue',
            Str:D :$node-font-color = 'white',
            Int:D :$node-font-size = 10,
            Str:D :$node-label-location = 'c',
            Str:D :$edge-color = 'steelblue',
            Numeric:D :$edge-width = 2,
            Bool :$svg = False,
            Str:D :$engine = 'dot') {

        my %core = self!dot-core(:$weights);
        my $format = "bgcolor=\"$background\";";
        $format ~= "\nnode [style=filled, shape=$node-shape, color=\"$node-color\", fillcolor=\"$node-fill-color\", fontsize=$node-font-size, fontcolor=\"$node-font-color\", labelloc=$node-label-location, width=$node-size, height=$node-size];";
        $format ~= "\nedge [color=\"$edge-color\", penwidth=$edge-width];";

        my $res = "{self.directed ?? 'digraph' !! 'graph'} \{\n$format\n{%core<vertexes>}\n{%core<edges>}\n\}";

        return $svg ?? self!dot-svg($res, :$engine) !! $res;
    }

    method !dot-core(:$weights is copy = Whatever) {
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

        return %(:$vertexes, :$edges);
    }

    method !dot-svg($input, :$engine) {
        my $temp-file = $*TMPDIR.child("temp-graph.dot");
        $temp-file.spurt: $input;
        my $svg-output = run($engine, $temp-file, '-Tsvg', :out).out.slurp-rest;
        unlink $temp-file;
        return $svg-output;
    }
}