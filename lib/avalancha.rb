# frozen_string_literal: true

require_relative 'pipeline/lexer'
require_relative 'pipeline/parser'

class Avalancha
  def self.build
    new(Pipeline::Lexer.new, Pipeline::Parser.new)
  end

  def initialize(lexer, parser)
    @lexer = lexer
    @parser = parser
  end

  def parse(input_path)
    tokens = lexer.lex_file(input_path)

    parser.parse(tokens)
  end

  private

  attr_reader :lexer, :parser
end