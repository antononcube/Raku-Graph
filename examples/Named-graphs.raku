#!/usr/bin/env raku
use v6.d;

use lib <. lib>;

use Graph::Star;
use Graph::Grid;
use Graph::Complete;

##---------------------------------------------------------
## Star
my $star = Graph::Star.new(leaves => 7, center => '0', prefix => '');

say $star;

say $star.mermaid;

##---------------------------------------------------------
## Grid
my $grid = Graph::Grid.new(rows => 7, columns => 5, prefix => '');

say $grid;

say $grid.mermaid;

##---------------------------------------------------------
## Complete
my $complete = Graph::Complete.new(n => 6, prefix => '');

say $complete;

say $complete.mermaid;