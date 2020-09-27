# frozen_string_literal: true

require 'rltk/lexer'

module Pipeline
  class Lexer < RLTK::Lexer
    rule(/--.*\n/)
    rule(/\s/)
  end
end
