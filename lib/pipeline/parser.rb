# frozen_string_literal: true

require 'rltk/parser'

module Pipeline
  class Parser < RLTK::Parser
    production(:program) do
      clause('') { ['program', [], []] }
    end

    finalize
  end
end
