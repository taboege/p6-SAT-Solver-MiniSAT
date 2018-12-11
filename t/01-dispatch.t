use Test;
use SAT::Solver::MiniSAT;

plan 6;

is MiniSAT.new.solve('t/aim/aim-100-2_0-no-1.cnf'.IO).&await,       False, "IO dispatch";
is MiniSAT.new.solve(slurp 't/aim/aim-100-2_0-no-1.cnf').&await,    False, "Str dispatch";
is MiniSAT.new.solve('t/aim/aim-100-2_0-no-1.cnf'.IO.lines).&await, False, "Seq dispatch";

my $DIMACS = q:to/EOF/;
p cnf 9 1
1 2 3 4 5 6 7 8 9 0
EOF
my $actee := cache $DIMACS.lines.map({
    if m/^ [ $<var>=[\d+] \s+ ]+ 0 $/ {
        slip gather {
            take $_;
            for $<var> -> $negate {
                take $<var>».Str.map(-> $n {
                    $n == $negate ?? -$n !! $n
                }).join(' ') ~ " 0";
            }
        }
    }
    elsif m/^ 'p cnf' \s $<vars>=[\d+] \s $<clauses>=[\d+] / {
        "p cnf $<vars> { $<clauses> * (1 + $<vars>) }"
    }
});

is MiniSAT.new.solve($DIMACS).&await,                        True, "Str dispatch";
is MiniSAT.new.solve($actee).&await,                         True, "List dispatch";
is MiniSAT.new.solve($actee.Supply.throttle(1, 0.3)).&await, True, "Supply dispatch";
