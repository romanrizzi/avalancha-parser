# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/pipeline/compiler'
require_relative '../../../lib/pipeline/lexer'
require_relative '../../../lib/pipeline/parser'

describe Pipeline::Compiler do
  it 'a' do
    tags = { 'A' => 0 }
    program = build_parsed_program(checks: [['print', ['cons', 'A', []]]])

    results = subject.compile_and_run(tags, program).split("\n")

    expect(results).to eq(['A'])
  end

  it 'b' do
    tags = { 'Cons' => 0, 'Zero' => 1, 'Suc' => 2, 'Nil' => 3 }

    tokens = Pipeline::Lexer.new.lex('print Cons(Zero, Cons(Suc(Zero), Cons(Suc(Suc(Zero)), Nil)))')
    program = Pipeline::Parser.new.parse(tokens)

    results = subject.compile_and_run(tags, program).split("\n")

    expect(results).to eq(['Cons(Zero, Cons(Suc(Zero), Cons(Suc(Suc(Zero)), Nil)))'])
  end

  def build_parsed_program(defs: [], checks: [])
    ['program', defs, checks]
  end
end
