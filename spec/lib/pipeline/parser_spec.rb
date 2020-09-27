# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/pipeline/lexer'
require_relative '../../../lib/pipeline/parser'

describe Pipeline::Parser do
  it 'parses an empty program' do
    string = "-- a comment \n"
    tokens = Pipeline::Lexer.new.lex(string)
    expected = ['program', [], []]

    expect(subject.parse(tokens)).to contain_exactly(*expected)
  end
end
