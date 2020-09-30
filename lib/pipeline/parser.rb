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
      clause('CHECK atomic_formula') { |_, a| ['check', a] }
    end

    production(:atomic_formula) do
      clause('TRUE') { |_| ['true'] }
      clause('FALSE') { |_| ['false'] }
      clause('LPAREN atomic_formula RPAREN') { |_, f, _| f }
      clause('expression') { |e1| ['equal', e1, ['true']] }
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
