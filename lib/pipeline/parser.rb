# frozen_string_literal: true

require 'rltk/parser'

module Pipeline
  class Parser < RLTK::Parser
    production(:program) do
      clause('') { ['program', [], []] }
      clause('program definition check') do |program, _deff, check|
        ['program', program[1], program[2].concat(check)]
      end
    end

    production(:definition) do
      clause('') { [] }
    end

    production(:check) do
      clause('CHECK atom') { |_, a| [['check', a]] }
    end

    production(:atom) do
      clause('TRUE') { |_| ['true'] }
      clause('FALSE') { |_| ['false'] }
      clause('expression EQ expression') { |e1, _, e2| ['equal', e1, e2] }
    end

    production(:expression) do
      clause('LOWERID') { |id| ['var', id] }
    end

    finalize
  end
end
