# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/pipeline/lexer'
require_relative '../../../lib/pipeline/parser'

describe Pipeline::Parser do
  it 'parses an empty program' do
    string = "-- a comment \n"
    tokens = Pipeline::Lexer.new.lex(string)
    expected = build_expected

    expect(subject.parse(tokens)).to contain_exactly(*expected)
  end

  it 'parses a check' do
    string = 'check true'
    tokens = Pipeline::Lexer.new.lex(string)
    expected = build_expected(checks: [['check', ['true']]])

    expect(subject.parse(tokens)).to contain_exactly(*expected)
  end

  it 'parses an variable equals check' do
    string = 'check foo == bar'
    tokens = Pipeline::Lexer.new.lex(string)
    expected = build_expected(checks:
      [
        ['check', ['equal', %w[var foo], %w[var bar]]]
      ])

    expect(subject.parse(tokens)).to contain_exactly(*expected)
  end

  it 'parses a check with recursive types' do
    string = 'check A(B(C),D(e,F(G))) == A(B(C),D(e,F(G)))'
    tokens = Pipeline::Lexer.new.lex(string)
    expected = build_expected(checks:
      [
        [
          'check',
          [
            'equal',
            [
              'cons', 'A', [
                ['cons', 'B', [['cons', 'C', []]]],
                ['cons', 'D', [%w[var e], ['cons', 'F', [['cons', 'G', []]]]]]
              ]
            ],
            [
              'cons', 'A', [
                ['cons', 'B', [['cons', 'C', []]]],
                ['cons', 'D', [%w[var e], ['cons', 'F', [['cons', 'G', []]]]]]
              ]
            ]
          ]
        ]
      ])

    expect(subject.parse(tokens)).to contain_exactly(*expected)
  end

  it 'parses a check' do
    string = 'check f()'
    tokens = Pipeline::Lexer.new.lex(string)
    expected = build_expected(checks: [['check', ['equal', ['app', 'f', []], ['true']]]])

    expect(subject.parse(tokens)).to contain_exactly(*expected)
  end

  def build_expected(defs: [], checks: [])
    ['program', defs, checks]
  end
end
