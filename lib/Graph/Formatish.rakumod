use v6.d;

use Graph::HighlightProcessing;

role Graph::Formatish
        does Graph::HighlightProcessing {

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

        my $coords = '';
        if self.vertex-coordinates ~~ Map:D {
            $coords = self.vertex-list.map({ "\"$_\" -> \{{self.vertex-coordinates{$_}.join(', ')}\}" }).join(',');
            $coords = ", VertexCoordinates -> \{$coords\}";
        }

        return "Graph[\{$vertexes\}, \{$edges\}, EdgeWeight -> \{$weights\}, DirectedEdges -> { self.directed }{$coords}{ $args }]";
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
    method dot(*%args) {
        if %args.elems == 0 || %args.elems == 1 && %args.keys.head eq 'weights' {
            my $weights = %args<weights> // Whatever;
            my %core = self!dot-core(:$weights, node-labels => %args<node-labels> // %args<vertex-labels> // True);
            return "{ self.directed ?? 'digraph' !! 'graph' } \{\n{ %core<vertexes> }\n{ %core<edges> }\n\}";
        } else {
            return self!dot-full(|%args);
        }
    }

    method !dot-full(
            :$weights is copy = Whatever,
            :$highlight = Whatever,
            :label(:$graph-label) is copy = Whatever,
            :size(:$graph-size) is copy = Whatever,
            :$pad is copy = Whatever,
            Str:D :labelloc(:$label-location) = 't',
            Str:D :fontcolor(:$font-color) = 'White',
            Int:D :fontsize(:$font-size) = 16,
            Str:D :$background = 'none',
            :vertex-labels(:$node-labels) is copy = True,
            Str:D :vertex-shape(:$node-shape) = 'circle',
            Str:D :vertex-color(:$node-color) = 'Black',
            Numeric:D :vertex-stroke-width(:node-stroke-width(:$node-penwidth)) = 1,
            Numeric:D :vertex-width(:$node-width) = 0.3,
            Numeric:D :vertex-height(:$node-height) = 0.3,
            :vertex-fixed-size(:$node-fixed-size) is copy = True,
            Str:D :vertex-fill-color(:$node-fill-color) = 'SteelBlue',
            Str:D :vertex-font-color(:$node-font-color) = 'White',
            Int:D :vertex-font-size(:$node-font-size) = 12,
            Str:D :vertex-label-location(:$node-label-location) = 'c',
            :$edge-labels is copy = False,
            Str:D :$edge-color = 'SteelBlue',
            Str:D :$edge-font-color = 'Ivory',
            Int:D :$edge-font-size = 10,
            Numeric:D :arrowsize(:$arrow-size) = 1,
            Numeric:D :edge-thickness(:edge-width(:$edge-penwidth)) = 2,
            :$splines is copy = Whatever,
            Bool:D :$mixed = False,
            Str:D :$preamble is copy = '',
            Bool :$svg = False,
            :format(:$output-format) is copy = Whatever,
            Str:D :$engine = 'dot') {

        # Process node labels
        if $node-labels.isa(Whatever) { $node-labels = True }
        die 'The value of $node-labels is expected to be a booolean, a string, a map, or Whatever.'
        unless $node-labels ~~ (Bool:D | Str:D | Map:D);

        # Get the vertex- and edge parts
        my %core = self!dot-core(:$weights, :$node-labels, :$edge-labels, :$mixed);

        # Splines
        if $splines ~~ Bool:D { $splines = $splines ?? 'true' !! 'false' }
        if $splines ~~ Str:D && !$splines.trim.chars { $splines = '""' }
        my @spline-specs = <none line false polyline curved ortho spline true>;
        die 'The argument $splines is expected to be Whatever, a Boolean, an empty string, or one of "' ~ @spline-specs.join('", "') ~ '".'
        unless $splines.isa(Whatever) || $splines ~~ Str:D && ($splines.lc ∈ @spline-specs || $splines eq '""');

        # Global format
        my $format = "bgcolor=\"$background\";";
        if $splines ~~ Str:D {
            $format ~= "\nsplines=$splines;";
        }
        if $node-fixed-size ~~ Bool:D { $node-fixed-size = $node-fixed-size ?? 'true' !! 'false' }
        $format ~= "\nnode [style=filled, fixedsize=$node-fixed-size, shape=$node-shape, color=\"$node-color\", fillcolor=\"$node-fill-color\", penwidth=$node-penwidth, fontsize=$node-font-size, fontcolor=\"$node-font-color\", labelloc=$node-label-location, width=$node-width, height=$node-height];";
        $format ~= "\nedge [color=\"$edge-color\", penwidth=$edge-penwidth, fontsize=$edge-font-size, fontcolor=\"$edge-font-color\", arrowsize=$arrow-size];";

        # This global setting is convenient, but when combining DOT specs
        # it is better to have it per node/vertex.
        #if !$node-labels {
        #    $format .= subst('node [', 'node [ label="", ')
        #}

        # Graph label
        $graph-label = do given $graph-label {
            when Str:D {
                "fontcolor = \"$font-color\";\nfontsize = \"$font-size\";\nlabelloc = \"$label-location\";label = \"$graph-label\";"
            }
            default { "" }
        }

        # Graph size
        $graph-size = do given $graph-size {
            when Str:D { "graph [size=\"$graph-size\"];" }
            when Numeric:D { "graph [size=\"{$_},{$_}!\"];" }
            when $_ ~~ (Array:D | List:D | Seq:D) && $_.elems ≥ 2 { "graph [size=\"{$_.join(',')}!\"];" }
            default { "" }
        }

        # Padding
        $pad = do given $pad {
            when Numeric:D { $pad }
            when $_ ~~ (Array:D | List:D | Seq:D) && $_.elems ≥ 2 { $pad.List.raku }
            default { Whatever }
        }

        with $pad {
            $graph-size = $graph-size ?? $graph-size.subst('];', ", pad=$pad];") !! "graph [pad=$pad];";
        }

        # Preliminary part
        if !$preamble {
            my $pre = "$graph-label\n$graph-size\n";
            if $pre.trim.chars == 0 { $pre = '' }
            $preamble = $pre ~ "\n" ~ $format;
        }

        # Main part
        my $res;
        if $highlight.isa(Whatever) {
            $res = "{ self.directed ?? 'digraph' !! 'graph' } \{\n$preamble\n{%core<vertexes>}\n{%core<edges>}\n\}";
        } else {
            $res = "{self.directed ?? 'digraph' !! 'graph'} \{\n$preamble\n{%core<vertexes>}\n";

            # In order to prevent multiple edge plotting, the highlighted edges have to be removed
            my @core-edges = |%core<edges>.split("\n");

            # Should be the same as the arrow determined in !dot-core
            my $arrow = self.directed ?? '->' !! '--';

            my %processed = self.process-highlight-spec($highlight, :directed-edges);
            my $highlight-part = '';
            for %processed.kv -> $color, %h {
                my $pre = "edge [color=\"$color\", penwidth=$edge-penwidth, arrowsize=$arrow-size];";

                # Get subgraph of edges to be highlighted
                my $gh = self.subgraph(%h<edges>.map({ $_.head => $_.tail }));

                # This is too cumbersome. It is better done to make the "main" !dot-core call
                # after this loop, or to use the complement subgraph in !dot-core above.
                my @edge-specs = %h<edges>.map({ "\"{$_.head}\" $arrow \"{$_.tail}\"" });
                my @edge-specs-rev;
                @edge-specs-rev = %h<edges>.map({ "\"{$_.tail}\" $arrow \"{$_.head}\"" }) if !self.directed;

                # Remove
                @core-edges = do for @core-edges -> $edge-spec {
                    my $present = False;
                    for [|@edge-specs, |@edge-specs-rev] -> $start {
                        $present = $edge-spec.starts-with($start);
                        last if $present;
                    }
                    $present ?? Empty !! $edge-spec
                }
                @core-edges .= flat;

                $highlight-part = $highlight-part ~ "\n\n" ~ [
                    $pre,
                    %h<vertexes>.map({ "\"{$_}\" [fillcolor=\"$color\", color=\"$color\"];",}).join("\n"),
                    #@edge-specs.join("\n")
                    $gh!dot-core(:$weights, :$node-labels, :$edge-labels, :$mixed)<edges>
                ].join("\n");
            }
            $res = $res ~ "\n" ~ @core-edges.join("\n") ~ $highlight-part ~ "\n\}";
        }

        # Output format
        if $svg { $output-format = 'svg' }
        if $output-format.isa(Whatever) { $output-format = 'dot' }

        # Result
        return $output-format eq 'dot' ?? $res !! self!dot-svg($res, :$engine, format => $output-format);
    }

    method !dot-core(:$weights is copy = Whatever, :$node-labels = True, :$edge-labels = False, Bool:D :$mixed = False) {

        #----------------------------------------------------------------------
        # Process edge labels
        my %edgeLabels;
        my $edge-lbl = '';
        given $edge-labels {
            when Bool:D {
                $edge-lbl = $edge-labels ?? '' !! ', label=""'
            }
            when $_ ~~ Map:D && $_.values.all ~~ Map:D {
                %edgeLabels = $edge-labels;
            }
            when $_ ~~ Str:D && $_.lc ∈ <weight edge-weight> {
                $weights = True;
            }
            # This will be used when the Graph class would have %edge-tag-list or similar
            #when $_ ~~ Str:D && $_.lc ∈ <tag label edge-tag edge-label edge-name> {
            #    %edgeLabels = self.vertex-list Z=> self.vertex-list
            #}
            default {
                warn 'Do not know how to process edge-labels spec.'
            }
        }

        #----------------------------------------------------------------------
        # Make the edges part
        my @dsEdges = self.edges(:dataset);

        # DOT edge spec
        my $arrow = self.directed ?? '->' !! '--';

        # Uniform weight
        my $allOne = [&&] @dsEdges.map({ $_<weight> == 1 });

        # Edge directions (for :mixed)
        my %directions;
        if $mixed {
            for @dsEdges {
                %directions{$_<from>}{$_<to>} = self.directed ?? 'forward' !! 'none';
                if self.has-edge($_<from>, $_<to>) && self.has-edge($_<to>, $_<from>) {
                    %directions{$_<from>}{$_<to>} = 'none'
                }
            }
        }

        # The edges
        my %marked;
        my $edges = do for @dsEdges -> $edge {
            if !(%marked{$edge<from>}{$edge<to>} // False) {
                my @spec;
                if %edgeLabels {
                    my $lbl = %edgeLabels{$edge<from>}{$edge<to>} // '';
                    if (%directions{$edge<from>}{$edge<to>} // '') eq 'none' || (%directions{$edge<to>}{$edge<from>} // '') eq 'none' {
                        $lbl = $lbl ?? $lbl !! (%edgeLabels{$edge<to>}{$edge<from>} // '');
                    }
                    @spec.push("label=\"$lbl\"");
                }
                if %directions {
                    @spec.push("dir={ (%directions{$edge<from>}{$edge<to>} // 'none') }");
                    %marked{$edge<from>}{$edge<to>} = True;
                    %marked{$edge<to>}{$edge<from>} = True;
                }
                if ($weights ~~ Bool:D) && $weights && !%edgeLabels {
                    @spec.push("weight={ $edge<weight>.Str }", "label={ $edge<weight>.Str }");
                }
                "\"{ $edge<from> }\" $arrow \"{ $edge<to> }\" " ~ (@spec ?? "[{ @spec.join(', ') }]" !! '')
            } else { '' }
        }.grep(*.chars).join("\n");

        #----------------------------------------------------------------------
        # Process node labels
        my %nodeLabels;
        my $lbl = '';
        given $node-labels {
            when Bool:D {
                $lbl = $node-labels ?? '' !! ', label=""'
            }
            when Map:D {
                %nodeLabels = $node-labels;
            }
            when $_ ~~ Str:D && $_.lc ∈ <name vertex-name> {
                %nodeLabels = self.vertex-list Z=> self.vertex-list
            }
        }

        # Make the vertexes part
        my $vertexes = do if self.vertex-coordinates {
            self.vertex-coordinates.map({ "\"{ $_.key }\" [pos=\"{ $_.value.join(',') }!\"{ %nodeLabels{$_.key}:exists ?? ', label="' ~ %nodeLabels{$_.key} ~ '"' !! $lbl }]" }).join(";\n");
        } elsif %nodeLabels {
            self.vertex-list.map({ "\"{ $_.key }\" [{ %nodeLabels{$_.key}:exists ?? 'label="' ~ %nodeLabels{$_.key} ~ '"' !! $lbl  }]" }).join(";\n");
        } else {
            '"' ~ self.vertex-list.join('"; "') ~ '";';
        }

        # Result
        return %(:$vertexes, :$edges);
    }

    method !dot-svg($input, Str:D :$engine = 'dot', Str:D :$format = 'svg') {
        my $temp-file = $*TMPDIR.child("temp-graph.dot");
        $temp-file.spurt: $input;
        my $svg-output = run($engine, $temp-file, "-T$format", :out).out.slurp-rest;
        unlink $temp-file;
        return $svg-output;
    }
}