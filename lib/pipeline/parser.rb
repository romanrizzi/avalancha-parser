# frozen_string_literal: true

require 'rltk/parser'

module Pipeline
  class Parser < RLTK::Parser
    production(:program) do
      clause('') { ['program', [], []] }
      clause('program definition check') do |program, _deff, check|
        ['program', program[1], program[2] << check]
      end
    end

    production(:definition) do
      clause('') { [] }
    end

    production(:check) do
      clause('CHECK neg_and_or_imp_formula') { |_, a| ['check', a] }
    end

    production(:neg_and_or_imp_formula) do
      clause('neg_and_or_formula') { |f| f }
      clause('neg_and_or_formula IMP neg_and_or_imp_formula') { |f1, _, f2| ['imp', f1, f2] }
    end

    production(:neg_and_or_formula) do
      clause('neg_and_formula') { |f| f }
      clause('neg_and_formula OR neg_and_or_formula') { |f1, _, f2| ['or', f1, f2] }
    end

    production(:neg_and_formula) do
      clause('neg_formula') { |f| f }
      clause('neg_formula AND neg_and_formula') { |f1, _, f2| ['and', f1, f2] }
    end

    production(:neg_formula) do
      clause('atomic_formula') { |f| f }
      clause('NOT neg_formula') { |_, f| ['not', f] }
    end

    production(:atomic_formula) do
      clause('TRUE') { |_| ['true'] }
      clause('FALSE') { |_| ['false'] }
      clause('LPAREN neg_and_or_imp_formula RPAREN') { |_, f, _| f }
      clause('expression') { |e1| ['equal', e1, ['cons', 'True', []]] }
      clause('expression EQ expression') { |e1, _, e2| ['equal', e1, e2] }
    end

    production(:expression) do
      clause('LOWERID') { |id| ['var', id] }
      clause('UPPERID') { |id| ['cons', id, []] }

      clause('LOWERID LPAREN expression_list RPAREN') { |id, _, el, _| ['app', id, el] }
      clause('UPPERID LPAREN expression_list RPAREN') { |id, _, el, _| ['cons', id, el] }
    end

    production(:expression_list) do
      clause('') { [] }
      clause('non_empty_expression_list') { |el| el }
    end

    production(:non_empty_expression_list) do
      clause('expression') { |e| [e] }
      clause('expression COMMA non_empty_expression_list') { |e, _, el| [e] + el }
    end

    finalize
  end
end
