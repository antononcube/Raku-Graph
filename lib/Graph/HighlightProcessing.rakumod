use v6.d;

# The code below is very similar to the highlight processing in "JavaScript::D3::Graph".

#============================================================
# Highlight spec processing
#============================================================
# Default highlight colors
my @defaultHighlightColors =
        <#faba8c #a71c00 #f29838 #feffdb #5f885e #ddede3 #7db79f #7da9ac #9fcede #cc6f84>;
# Of color scheme "schemeCategory10"
# my @colors = <#1f77b4 #ff7f0e #2ca02c #d62728 #9467bd #8c564b #e377c2 #7f7f7f #bcbd22 #17becf>;

sub is-positional-of-strings-or-pairs($list) {
    return False unless $list ~~ Positional:D;
    for |$list -> $item {
        return False unless $item ~~ Str:D or $item ~~ Pair:D;
    }
    return True;
}

role Graph::HighlightProcessing {

    proto method process-highlight-spec($highlight, Bool :directed(:$directed-edges) = False) is export {*}

    multi method process-highlight-spec(Bool :directed(:$directed-edges) = False) {
        return self.process-highlight-spec([|self.vertex-list, |self.edges], directed-edges => self.directed);
    }

    multi method process-highlight-spec($highlight, Bool :directed(:$directed-edges) = False) {
        if !$highlight {
            return Empty
        }
        my %spec = do given $highlight {
            when is-positional-of-strings-or-pairs($_) {
                %('DarkOrange' => $_)
            }

            when ($_ ~~ Positional:D || $_ ~~ Seq:D) && ([&&] |$_.map(*.&is-positional-of-strings-or-pairs)) {
                if $_.elems ≤ @defaultHighlightColors.elems {
                    (@defaultHighlightColors[0 .. $_.elems].Array Z=> $_.Array).Hash
                } else {
                    die "Please provide a map of color-to-highlight-group pairs.";
                }
            }

            when $_ ~~ Hash:D && ([&&] |$_.values.map(*.&is-positional-of-strings-or-pairs)) {
                $_
            }

            default {
                die "The highlight spec is expected to be a list of vertexes or edges, " ~
                        "or a list of such lists, or a Map of colors to such lists."
            }
        };

        %spec = do if $directed-edges {
            %spec.map({
                $_.key => %( vertexes => $_.value.grep({ $_ ~~ Str:D }),
                             edges => $_.value.grep({ $_ ~~ Pair:D }).map({ $_.kv })».cache
                ) });
        } else {
            %spec.map({
                $_.key => %(
                    vertexes => $_.value.grep({ $_ ~~ Str:D }),
                    edges => [|$_.value.grep({ $_ ~~ Pair:D }).map({ $_.kv }),
                              |$_.value.grep({ $_ ~~ Pair:D }).map({ $_.kv.reverse })]».cache
                ) });
        }

        return %spec;
    }
}