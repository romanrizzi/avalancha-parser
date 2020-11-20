# frozen_string_literal: true

require_relative 'pipeline/lexer'
require_relative 'pipeline/parser'
require_relative 'pipeline/compiler'
require 'byebug'

class Avalancha
  def self.build
    new(
      Pipeline::Lexer.new,
      Pipeline::Parser.new,
      Pipeline::Compiler.new
    )
  end

  def initialize(lexer, parser, compiler)
    @lexer = lexer
    @parser = parser
    @compiler = compiler
  end

  def lex(input_path)
    lexer.lex_file(input_path)
  end

  def parse(input_path)
    tokens = lex(input_path)

    parser.parse(tokens)
  end

  def compile(input_path)
    tags = get_tags_from(input_path)

    compiler.compile_and_run(tags, parse(input_path))
  end

  private

  attr_reader :lexer, :parser, :compiler

  def get_tags_from(input_path)
    tags = {}
    tag_n = 0

    File.foreach(input_path) do |line|
      line.scan(/[A-Z][_a-zA-Z0-9]*/).each do |id|
        next unless tags[id].nil?

        tags[id] = tag_n
        tag_n += 1
      end
    end

    tags
  end
end
