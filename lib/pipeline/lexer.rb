# frozen_string_literal: true

require 'rltk/lexer'

module Pipeline
  class Lexer < RLTK::Lexer
    rule(/--.*\n/)
    rule(/\s/)

    rule(/check/) { :CHECK }
    rule(/true/) { :TRUE }
    rule(/false/) { :FALSE }

    rule(/==/) { :EQ }

    rule(/[a-z][_a-zA-Z0-9]*/) { |id| [:LOWERID, id] }
  end
end
