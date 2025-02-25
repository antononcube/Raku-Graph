#!/usr/bin/env raku
use v6.d;

use Graph::Random;
use Graph::Distribution;

my @dsEdges =
        %('from' => '1', 'to' => '2', 'weight' => 1), %('from' => '1', 'to' => '5', 'weight' => 1),
        %('from' => '1', 'to' => '6', 'weight' => 1), %('from' => '2', 'to' => '3', 'weight' => 1),
        %('from' => '2', 'to' => '7', 'weight' => 1), %('from' => '3', 'to' => '4', 'weight' => 1),
        %('from' => '3', 'to' => '8', 'weight' => 1), %('from' => '4', 'to' => '5', 'weight' => 1),
        %('from' => '4', 'to' => '9', 'weight' => 1), %('from' => '5', 'to' => '10', 'weight' => 1),
        %('from' => '6', 'to' => '7', 'weight' => 1),
        %('from' => '6', 'to' => '10', 'weight' => 1), %('from' => '7', 'to' => '8', 'weight' => 1),
        %('from' => '8', 'to' => '9', 'weight' => 1), %('from' => '9', 'to' => '10', 'weight' => 1);

my $g = Graph.new(@dsEdges);

say $g.wl;

my $res = $g.find-postman-tour();

say $res;