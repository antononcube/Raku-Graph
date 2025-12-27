use v6.d;

sub EXPORT {
    use Graph;
    use Graph::Circulant;
    use Graph::Complete;
    use Graph::CompleteKaryTree;
    use Graph::Cycle;
    use Graph::Grid;
    use Graph::HexagonalGrid;
    use Graph::Hypercube;
    use Graph::Indexed;
    use Graph::KnightTour;
    use Graph::Nested;
    use Graph::Path;
    use Graph::Petersen;
    use Graph::Relation;
    use Graph::Star;
    use Graph::TriangularGrid;
    use Graph::Wheel;

    use Graph::Distribution;
    use Graph::Random;

    Map.new:
            'Graph' => Graph,
            'Graph::Circulant' => Graph::Circulant,
            'Graph::Complete' => Graph::Complete,
            'Graph::CompleteKaryTree' => Graph::CompleteKaryTree,
            'Graph::Cycle' => Graph::Cycle,
            'Graph::Grid' => Graph::Grid,
            'Graph::HexagonalGrid' => Graph::HexagonalGrid,
            'Graph::Hypercube' => Graph::Hypercube,
            'Graph::Indexed' => Graph::Indexed,
            'Graph::KnightTour' => Graph::KnightTour,
            'Graph::Nested' => Graph::Nested,
            'Graph::Path' => Graph::Path,
            'Graph::Petersen' => Graph::Petersen,
            'Graph::Relation' => Graph::Relation,
            'Graph::Star' => Graph::Star,
            'Graph::TriangularGrid' => Graph::TriangularGrid,
            'Graph::Wheel' => Graph::Wheel,
            'Graph::Distribution' => Graph::Distribution,
            'Graph::Random' => Graph::Random
}
