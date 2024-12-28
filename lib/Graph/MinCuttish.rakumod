use v6.d;

role Graph::MinCuttish {

    method !karger-contract($g is copy, UInt:D :$th = 2, Str:D :$sep = '⎦⎦⎦@⎡⎡⎡') {
        while $g.vertex-count > 2 {
            my $edge = $g.edges.pick;
            $g = $g.vertex-contract($edge.kv, :!clone).vertex-replace($edge.key => $edge.kv.join($sep), :!clone);
        }
        return $g;
    }

    method !karger-min-cut($g is copy, Str:D :$sep = '~~~') {
        $g = self!karger-contract(self.clone, th => 2, :$sep);
        my ($first, $second) = |$g.vertex-list.map({ $_.split($sep, :skip-empty).List }).List;
        my $cut = 0;
        $first.map({ $cut += (self.adjacency-list{$_} (&) $second).elems });
        return ($cut, ($first, $second));
    }

    method !fast-min-cut($g, Str:D :$sep = '~~~') {
        if $g.vertex-count ≤ 6 {
            return self!karger-min-cut($g, :$sep)
        } else {
            my $th = ceiling(1 + self.vertex-count / sqrt(2));
            my $g1 = self!karger-contract($g.clone, :$th, :$sep);
            my $g2 = self!karger-contract($g, :$th, :$sep);
            my $res1 = self!fast-min-cut($g1, :$sep);
            my $res2 = self!fast-min-cut($g2, :$sep);
            return $res1.head < $res2.head ?? $res1 !! $res2;
        }
    }

    method find-minimum-cut(:$method is copy = Whatever, :$sep is copy = Whatever) {
        if $method.isa(Whatever) || $method.isa(WhateverCode) { $method = 'karger' }
        die 'The value of $method is expected to be string or Whatever.'
        unless $method ~~ Str:D;

        # Something that is not in the vertex names
        $sep = '⎦⎦⎦@⎡⎡⎡' unless $sep ~~ Str:D;

        return do given $method.lc {
            when 'karger' { self!karger-min-cut(self.clone, :$sep) }
            when 'karger-stein' { self!fast-min-cut(self.clone, :$sep) }
            default {
                die 'Unknown method. Expected method values are "karger", "karger-stein", or Whatever.'
            }
        }
    }
}
