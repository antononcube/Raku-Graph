#!/usr/bin/env raku
use v6.d;

use Graph::Random;
use Graph::Distribution;

my @dsEdges =
        %('from'=>'Maywood','to'=>'Downers','weight'=>14),
        %('from'=>'Maywood','to'=>'Oakbrook','weight'=>28),
        %('from'=>'Maywood','to'=>'Addison','weight'=>10),
        %('from'=>'Downers','to'=>'Grove','weight'=>25),
        %('from'=>'Downers','to'=>'Stickney','weight'=>23),
        %('from'=>'Downers','to'=>'Wheaton','weight'=>20),
        %('from'=>'Downers','to'=>'Oakbrook','weight'=>27),
        %('from'=>'Oakbrook','to'=>'Stickney','weight'=>11),
        %('from'=>'Oakbrook','to'=>'Addison','weight'=>17),
        %('from'=>'Addison','to'=>'McCook','weight'=>21),
        %('from'=>'Grove','to'=>'Wheaton','weight'=>10),
        %('from'=>'Stickney','to'=>'Wheaton','weight'=>15),
        %('from'=>'Stickney','to'=>'Bellwood','weight'=>20),
        %('from'=>'Wheaton','to'=>'Bellwood','weight'=>10),
        %('from'=>'Bellwood','to'=>'McCook','weight'=>28);

my $g = Graph.new(@dsEdges);

say $g.wl;

my $method = 'prim';
my $res = $g.find-spanning-tree(:$method);

say $res.wl;