unit module Test::SAT::Solver;

use Test;

#| Verify that the SAT::Solver in $*SAT-SOLVER makes accurate decisions.
sub sat-ok ($p (IO() :key($file), :value($answer))) is export {
    my $yesno = await $*SAT-SOLVER.new.solve: $file;
    is $yesno, $answer, "correct decision for $file";
}

#|« Verify that the certifying SAT::Solver in $*SAT-SOLVER makes accurate
decisions and that the witness it outputs is a satisfying assignment.
»
sub witness-ok ($p (IO() :key($file), :value($answer))) is export {
    subtest "$file" => {
        plan 2;
        my $yesno = await $*SAT-SOLVER.new.solve: $file, my $witness;
        is $yesno, $answer, "correct decision";
        if $yesno {
            if $witness.DEFINITE {
                is eval-DIMACS($file, $witness), $yesno, "consistent witness";
            }
            else {
                flunk "witness not delivered";
            }
        }
        else {
            pass "no short witness required for UNSAT";
        }
    }
}

sub eval-DIMACS ($file, $assignment) {
    for $file.IO.lines {
        next unless m/^ '-'? \d /;
        my $lits = set((m:g/ '-'? \d+ /)».Int) ∖ 0;
        return False if $assignment ∩ $lits === ∅;
    }
    return True;
}
