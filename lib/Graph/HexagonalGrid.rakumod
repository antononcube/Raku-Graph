use v6.d;

use Graph;
use Graph::Indexed;

class Graph::HexagonalGrid is Graph {
    has Int:D $.rows is required;
    has Int:D $.columns is required;

    constant $tol = 1e-12;

    submethod BUILD(:$!rows!,
                    :$!columns!,
                    :$prefix = '', Str:D :$sep = '_', Bool:D :d(:directed-edges(:$directed)) = False) {
        my @cells = gather for ^$!columns -> $j {
            for ^$!rows -> $k {
                take (^6).map(-> $i {
                    my $angle = $i * pi / 3;
                    my $x = sqrt(3) * (2 * $j + $k - 2) + 2 * cos($angle + pi / 2);
                    my $y = 3 * $k - 2 + 2 * sin($angle + pi / 2);
                    [$x.round($tol), $y.round($tol)];
                }).cache
            }
        };

        my @edges =
                @cells.map({
                    my @t = $_.rotor(2 => -1);
                    @t = @t.push([$_.tail, $_.head]);
                    @t.map({ %(from => $_.head.Str, to => $_.tail.Str) }).Array
                }).map(*.Slip);
        my @vertexes = @cells.map(*.Slip).unique;
        my $vertex-coordinates = @vertexes.map({ $_.Str => $_ }).Hash;
        my $g = Graph::Indexed.new: Graph.new(@vertexes, @edges, :$vertex-coordinates, :$directed);
        self.vertex-coordinates = $g.vertex-coordinates;
        self.adjacency-list = $g.adjacency-list;
    }

    multi method new(Int:D $rows, Int:D $columns,
                     Str:D :$prefix = '',
                     Str:D :$sep = '_',
                     Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:$rows, :$columns, :$prefix, :$sep, :$directed);
    }
    multi method new(Int:D :m(:$rows), Int:D :n(:$columns),
                     Str:D :$prefix = '',
                     Str:D :$sep = '_',
                     Bool:D :d(:directed-edges(:$directed)) = False) {
        self.bless(:$rows, :$columns, :$prefix, :$sep, :$directed);
    }
}

