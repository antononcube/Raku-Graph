unit module Graph::Utilities;

our sub reallyflat (+@list) {
    gather @list.deepmap: *.take
}

#============================================================
# Paired UInt arguments
#============================================================

our sub ProcessPairedUIntArgs($n is copy, $m is copy, $n-default) {

    given ($n, $m) {
        when $_.head.isa(Whatever) && $_.tail ~~ UInt:D { $n = $m }
        when $_.head ~~ UInt:D && $_.tail.isa(Whatever) { $m = $n }
        when $_.head ~~ UInt:D && $_.tail ~~ UInt:D {
            # do nothing
        }
        when $_.head.isa(Whatever) && $_.tail.isa(Whatever) {
            $n = $n-default;
            $m = $n;
        }
    }

    return ($n, $m);
}