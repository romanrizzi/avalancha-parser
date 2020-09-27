# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/pipeline/lexer'

describe Pipeline::Lexer do
  it 'ignores whitespace' do
    assert_tokens_correctly_generated('', [:EOS])
    assert_tokens_correctly_generated(' ', [:EOS])
    assert_tokens_correctly_generated("\t", [:EOS])
    assert_tokens_correctly_generated("\r", [:EOS])
    assert_tokens_correctly_generated("\n", [:EOS])
  end

  it 'ignores comments' do
    assert_tokens_correctly_generated("-- a comment \n", [:EOS])
  end

  def assert_tokens_correctly_generated(string, expected_types)
    tokens = subject.lex(string)

    token_types = tokens.map(&:type)

    expect(token_types).to contain_exactly(*expected_types)
  end
end
