unit class SAT::Solver::MiniSAT is export;

multi method solve (IO::Path $file --> Promise) {
    self.solve: $file.lines
}

multi method solve (Str $DIMACS --> Promise) {
    self.solve: $DIMACS.lines
}

multi method solve (List $lines --> Promise) {
    self.solve: $lines.Supply
}

multi method solve (Seq $lines --> Promise) {
    self.solve: $lines.Supply
}

multi method solve (Supply $lines --> Promise) {
    my $out;
    with my $proc = Proc::Async.new: :w, %?RESOURCES<minisat>, '-verb=0' {
        $out = .stdout.lines;
        .start and await .ready;
        react whenever $lines -> $line {
            .put: $line;
            LAST .close-stdin;
        }
    }

    $out.map({
        m/^ <( 'UN'? )> 'SATISFIABLE' / ??
            $/ ne "UN" !! Empty
    }).Promise
}

=begin pod

=head1 NAME

SAT::Solver::MiniSAT - SAT solver MiniSAT

=head1 SYNOPSIS

  use SAT::Solver::MiniSAT;

  say await MiniSAT.new.solve($my-cnf-file.IO)

=head1 DESCRIPTION

SAT::Solver::MiniSAT wraps the C<minisat> executable (bunled with the module)
used to decide whether a satisfying assignment for a Boolean formula given
in the C<DIMACS cnf> format exists. This is known as the C<SAT> problem
associated with the formula. MiniSAT does not produce a witness for
satisfiability.

Given a DIMACS cnf problem, it starts C<minisat>, feeds it the problem and
return a Promise which will be kept with the C<SAT> answer found or broken on
error.

=head1 AUTHOR

Tobias Boege <tboege@ovgu.de>

=head1 COPYRIGHT AND LICENSE

Copyright 2018 Tobias Boege

This library is free software; you can redistribute it and/or modify it
under the Artistic License 2.0.

=end pod
