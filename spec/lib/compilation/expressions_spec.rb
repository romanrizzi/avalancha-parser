# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/compilation/expressions'
require_relative '../../../lib/pipeline/compiler'

describe Compilation::Expressions do
  it 'compiles simple expressions' do
    expression = ['cons', 'Zero', []]
    expected = build_expression(1, 0, [])

    compiled_expression = subject.compile(expression, context)

    expect(compiled_expression[:code]).to eq(expected)
  end

  it 'compiles complex expression' do
    # Cons(Suc(Suc(Zero)), Nil)
    expression = [
      'cons',
      'Cons',
      [
        ['cons', 'Suc', [['cons', 'Suc', [['cons', 'Zero', []]]]]],
        ['cons', 'Nil', []]
      ]
    ]

    expected = build_expression(1, 0, [])
    expected += build_expression(2, 1, [0])
    expected += build_expression(2, 2, [1])
    expected += build_expression(3, 3, [])
    expected += build_expression(0, 4, [2, 3])

    compiled_expression = subject.compile(expression, context)

    expect(compiled_expression[:code]).to eq(expected)
  end

  it 'compiles an expression with application' do
    fcontext = context
    fcontext[:functions] = { 'uno' => 'f_0' }

    expression = ['cons', 'Suc', [['app', 'uno', []]]]

    expected = build_app(0, 'f_0')
    expected += build_expression(2, 1, [0])

    compiled_expression = subject.compile(expression, fcontext)

    expect(compiled_expression[:code]).to eq(expected)
  end

  def context
    tags = { 'Cons' => 0, 'Zero' => 1, 'Suc' => 2, 'Nil' => 3 }
    Pipeline::Compiler.new.build_fresh_context(tags)
  end

  def build_app(var, f_name)
    "Term* e_#{var} = #{f_name}();\n"
  end

  def build_expression(tag, var, children)
    expression = <<~HEREDOC
      \x20\x20\x20 Term* e_#{var} = new Term();
      \x20\x20\x20 e_#{var}->tag = #{tag};
      \x20\x20\x20 e_#{var}->refcnt = 0;
    HEREDOC

    children.each do |c|
      expression += <<~HEREDOC
        \x20\x20\x20 e_#{var}->children.push_back(e_#{c});
      HEREDOC
    end

    expression
  end
end
