#!/usr/bin/env raku
use v6.d;

use lib <. lib>;

use Graph::Complete;
use Graph::Cycle;
use Graph::Grid;
use Graph::Star;
use Graph::Wheel;

##---------------------------------------------------------
## Complete
my $complete = Graph::Complete.new(n => 6, prefix => '');

say $complete;

say $complete.mermaid;

##---------------------------------------------------------
## Cycle
my $cycle = Graph::Cycle.new(n => 6, prefix => '');

say $cycle;

say $cycle.mermaid;

##---------------------------------------------------------
## Grid
my $grid = Graph::Grid.new(rows => 7, columns => 5, prefix => '');

say $grid;

say $grid.mermaid;

##---------------------------------------------------------
## Star
my $star = Graph::Star.new(leaves => 7, center => '0', prefix => '');

say $star;

say $star.mermaid;

##---------------------------------------------------------
## Wheel
my $wheel = Graph::Wheel.new(spokes => 7, center => '0', prefix => '');

say $wheel;

say $wheel.mermaid;
