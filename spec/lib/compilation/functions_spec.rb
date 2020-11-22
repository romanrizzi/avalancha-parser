# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/compilation/functions'
require_relative '../../../lib/compilation/expressions'
require_relative '../../../lib/pipeline/compiler'

describe Compilation::Functions do
  it 'compiles a simple function' do
    fun_number = 0
    rule = ['cons', 'Suc', [['cons', 'Zero', []]]]
    function = [
      'fun',
      'uno',
      ['sig', [], '_'],
      ['pre', ['true']],
      ['post', ['true']],
      [
        ['rule', [], rule]
      ]
    ]
    expected_sig = "Term* f_#{fun_number}();"
    fun_body = Compilation::Expressions.new.compile(rule, context)
    expected_fun = <<~HEREDOC
      Term* f_#{fun_number}() {
      #{fun_body[:code]}
          return e_#{fun_body[:last_var_used]};
      }
    HEREDOC

    compiledf = described_class.new.compile(function, context)

    expect(compiledf[:signature]).to eq(expected_sig)
    expect(compiledf[:code]).to eq(expected_fun)
  end

  def context
    tags = { 'Cons' => 0, 'Zero' => 1, 'Suc' => 2, 'Nil' => 3 }
    Pipeline::Compiler.new.build_fresh_context(tags)
  end
end
