#!/usr/bin/env raku
use v6.d;

use Graph::Circulant;
use Graph::Complete;
use Graph::CompleteKaryTree;
use Graph::Cycle;
use Graph::Grid;
use Graph::Hypercube;
use Graph::Path;
use Graph::Petersen;
use Graph::Star;
use Graph::Wheel;

my $viz = 'wl';

##---------------------------------------------------------
## Circulant
say '=' x 100;
say 'Circulant';
say '-' x 100;
my $cicrculant = Graph::Circulant.new(n => 5, j => 3, prefix => '');

say $cicrculant;

say $cicrculant."$viz"();

##---------------------------------------------------------
## Complete
say '=' x 100;
say 'Complete';
say '-' x 100;
my $complete = Graph::Complete.new(n => 6, prefix => '');

say $complete;

say $complete."$viz"();

## Exporting to WL with WL Graph options:
# say $complete.wl(ImageSize => 600, GraphLayout => "LayeredEmbedding", Background => "`GrayLevel[0.3]`");

##---------------------------------------------------------
## CompleteKaryTree
say '=' x 100;
say 'CompleteKaryTree';
say '-' x 100;
my $kary-tree = Graph::CompleteKaryTree.new(n => 4, k => 3, prefix => '');

say $kary-tree;

say $kary-tree."$viz"();


##---------------------------------------------------------
## Cycle
say '=' x 100;
say 'Cycle';
say '-' x 100;
my $cycle = Graph::Cycle.new(n => 6, prefix => '');

say $cycle;

say $cycle."$viz"();

##---------------------------------------------------------
## Hypercube
say '=' x 100;
say 'Hypercube';
say '-' x 100;
my $hypercube = Graph::Hypercube.new(n => 3, prefix => 'g');

say $hypercube;

say $hypercube."$viz"();

##---------------------------------------------------------
## Grid
say '=' x 100;
say 'Grid';
say '-' x 100;
my $grid = Graph::Grid.new(rows => 7, columns => 5, prefix => 'g');

say $grid;

say $grid."$viz"();

##---------------------------------------------------------
## KnightTour
say '=' x 100;
say 'KnightTour';
say '-' x 100;

my $knight = Graph::Grid.new(rows => 7, columns => 5, prefix => '');

say $knight;

say $knight."$viz"();

##---------------------------------------------------------
## Star
say '=' x 100;
say 'Star';
say '-' x 100;
my $star = Graph::Star.new(leaves => 7, center => '0', prefix => '', :directed);

say $star;

say $star."$viz"();

##---------------------------------------------------------
## Path
say '=' x 100;
say 'Path';
say '-' x 100;
my $path = Graph::Path.new('a'..'k', prefix => 'note:', :directed);

say $path;

say $path."$viz"();


##---------------------------------------------------------
## Petersen
say '=' x 100;
say 'Petersen';
say '-' x 100;
my $petersen = Graph::Petersen.new(prefix => '');

say $petersen;

say $petersen."$viz"();

##---------------------------------------------------------
## Wheel
say '=' x 100;
say 'Wheel';
say '-' x 100;
my $wheel = Graph::Wheel.new(spokes => 7, center => '0', prefix => '');

say $wheel;

say $wheel."$viz"();
