use v6.d;

use Graph;
use Graph::Indexed;

# This very contrived code was supposed to be an "easy" derivative
# of the code of Graph::HexagonalGraph.
# The reason for using the "same code base" (i.e. approach) was the making of hexagonal mazes.
# The code has to be refactored with much more straightforward derivation.
class Graph::TriangularGrid is Graph {
    has Int:D $.rows is required;
    has Int:D $.columns is required;

    constant $tol = 1e-12;

    submethod BUILD(:$!rows!,
                    :$!columns!,
                    :$prefix = '',
                    Numeric:D :$scale = 1,
                    Bool:D :d(:directed-edges(:$directed)) = False) {
        # With 6 we get hexagonal grid
        my $n = 3;
        my @top-vertices;
        my @right-vertices;
        my @cells;
        for ^$!columns -> $j {
            for ^$!rows -> $k {
                my @cell;
                for (^$n) -> $i {
                    my $angle = $i * 2 * pi / $n;
                    my $x = $scale * (sqrt(3) * (2 * $j + $k - 2) + 2 * cos($angle + pi / 2));
                    my $y = $scale * (3 * $k - 2 + 2 * sin($angle + pi / 2));

                    my @p = $x.round($tol), $y.round($tol);

                    if $j == ($!columns - 1) && $i == 2 { @right-vertices .= push(@p) }

                    if $k == ($!rows - 1) && $i == 0 { @top-vertices .= push(@p) }

                    @cell .= push(@p)
                }
                @cells .= push(@cell)
            }
        };

        my @end-vertex = 2 * @top-vertices[*-1][0] - @top-vertices[*-2][0], @top-vertices.tail.tail;

        @top-vertices .= push(@end-vertex);
        @right-vertices .= push(@end-vertex);

        my @edges =
                @cells.map({
                    my @t = $_.rotor(2 => -1);
                    @t = @t.push([$_.tail, $_.head]);
                    @t.map({ %(from => $_.head.Str, to => $_.tail.Str) }).Array
                }).map(*.Slip);

        @edges .= append( @top-vertices.rotor(2 => -1).map({ %(from => $_.head.Str, to => $_.tail.Str) }) );
        @edges .= append( @right-vertices.rotor(2 => -1).map({ %(from => $_.head.Str, to => $_.tail.Str) }) );

        my @vertexes = @cells.map(*.Slip).Array.push(@end-vertex).unique.sort;

        my $vertex-coordinates = @vertexes.map({ $_.Str => $_ }).Hash;

        my $g = Graph::Indexed.new:
                Graph.new(@vertexes, @edges, :$vertex-coordinates, :$directed),
                as => { $_.split(/\s/, :skip-empty)».trim».Real },
                :$prefix;

        self.vertex-coordinates = $g.vertex-coordinates;
        self.adjacency-list = $g.adjacency-list;
    }

    multi method new(Int:D $rows, *%args) {
        self.new(:$rows, columns => $rows, |%args);
    }

    multi method new(Int:D $rows, Int:D $columns,
                     Str:D :$prefix = '',
                     Numeric:D :$scale = 1,
                     Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:$rows, :$columns, :$prefix, :$scale, :$directed);
    }

    multi method new(Int:D :m(:$rows), Int:D :n(:$columns),
                     Str:D :$prefix = '',
                     Numeric:D :$scale = 1,
                     Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:$rows, :$columns, :$prefix, :$scale, :$directed);
    }
}

