# frozen_string_literal: true

require 'rltk/lexer'

module Pipeline
  class Lexer < RLTK::Lexer
    rule(/--.*\n/)
    rule(/\s/)

    rule(/check/) { :CHECK }
    rule(/true/) { :TRUE }
    rule(/false/) { :FALSE }

    rule(/not/) { :NOT }
    rule(/and/) { :AND }
    rule(/or/) { :OR }
    rule(/==/) { :EQ }

    rule(/[a-z][_a-zA-Z0-9]*/) { |id| [:LOWERID, id] }
    rule(/[A-Z][_a-zA-Z0-9]*/) { |id| [:UPPERID, id] }

    rule(/\(/) { :LPAREN }
    rule(/\)/) { :RPAREN }
    rule(/,/) { :COMMA }
  end
end
