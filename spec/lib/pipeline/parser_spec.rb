# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/pipeline/lexer'
require_relative '../../../lib/pipeline/parser'
require 'byebug'

describe Pipeline::Parser do
  it 'parses an empty program' do
    string = "-- a comment \n"
    tokens = Pipeline::Lexer.new.lex(string)
    expected = ['program', [], []]

    expect(subject.parse(tokens)).to contain_exactly(*expected)
  end

  it 'parses a check' do
    string = 'check true'
    tokens = Pipeline::Lexer.new.lex(string)
    expected = ['program', [], [['check', ['true']]]]

    expect(subject.parse(tokens)).to contain_exactly(*expected)
  end

  it 'pars' do
    string = 'check foo == bar'
    tokens = Pipeline::Lexer.new.lex(string)
    expected = [
      'program',
      [],
      [
        ['check', ['equal', %w[var foo], %w[var bar]]]
      ]
    ]

    expect(subject.parse(tokens)).to contain_exactly(*expected)
  end
end
