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

  context 'keywords' do
    it { assert_tokens_correctly_generated('check', %i[CHECK EOS]) }
    it { assert_tokens_correctly_generated('true', %i[TRUE EOS]) }
    it { assert_tokens_correctly_generated('false', %i[FALSE EOS]) }
  end

  context 'reserved symbols' do
    it { assert_tokens_correctly_generated('==', %i[EQ EOS]) }
    it { assert_tokens_correctly_generated('==', %i[EQ EOS]) }
  end

  context 'identifiers' do
    it { assert_tokens_correctly_generated('asd', %i[LOWERID EOS]) }
    it { assert_tokens_correctly_generated('Zero', %i[UPPERID EOS]) }
    it { assert_tokens_correctly_generated('Zero()', %i[UPPERID LPAREN RPAREN EOS]) }
    it { assert_tokens_correctly_generated('Suc(Zero)', %i[UPPERID LPAREN UPPERID RPAREN EOS]) }
    it { assert_tokens_correctly_generated('A(b,C)', %i[UPPERID LPAREN LOWERID COMMA UPPERID RPAREN EOS]) }
  end

  it { assert_tokens_correctly_generated('f()', %i[LOWERID LPAREN RPAREN EOS]) }
  it { assert_tokens_correctly_generated('check not foo', %i[CHECK NOT LOWERID EOS]) }

  it { assert_tokens_correctly_generated('check A and B ', %i[CHECK UPPERID AND UPPERID EOS]) }
  it { assert_tokens_correctly_generated('check A or B ', %i[CHECK UPPERID OR UPPERID EOS]) }
  it { assert_tokens_correctly_generated('check A imp B ', %i[CHECK UPPERID IMP UPPERID EOS]) }

  context 'function definitions' do
    it { assert_tokens_correctly_generated('fun foo2 : -> _', %i[FUN LOWERID COLON ARROW UNDERSCORE EOS]) }
    it { assert_tokens_correctly_generated('fun foo4 : _ -> _', %i[FUN LOWERID COLON UNDERSCORE ARROW UNDERSCORE EOS]) }
    it do
      assert_tokens_correctly_generated(
        'fun foo10:_,y->_',
        %i[FUN LOWERID COLON UNDERSCORE COMMA LOWERID ARROW UNDERSCORE EOS]
      )
    end
  end

  context 'pre and post conditions' do
    it { assert_tokens_correctly_generated('fun foo1?false', %i[FUN LOWERID QUESTION FALSE EOS]) }
    it { assert_tokens_correctly_generated('fun foo2!a', %i[FUN LOWERID BANG LOWERID EOS]) }
  end

  def assert_tokens_correctly_generated(string, expected_types)
    tokens = subject.lex(string)

    token_types = tokens.map(&:type)

    expect(token_types).to contain_exactly(*expected_types)
  end
end
