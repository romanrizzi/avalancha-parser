# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/compilation/functions'
require_relative '../../../lib/compilation/expressions'
require_relative '../../../lib/pipeline/compiler'

describe Compilation::Functions do
  it 'compiles a simple function' do
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
    expected_sig = 'Term* f_0();'
    fun_body = Compilation::Expressions.new.compile(rule, context)
    expected_fun = <<~HEREDOC
      Term* f_0() {
      #{fun_body[:code]}
          return e_#{fun_body.dig(:context, :next_var_id) - 1};
      }
    HEREDOC

    compiledf = subject.compile(function, context)

    expect(compiledf[:signature]).to eq(expected_sig)
    expect(compiledf[:code]).to eq(expected_fun)
  end

  it 'compiles a function with multiple rules' do
    function = [
      'fun',
      'neg',
      ['sig', ['_'], '_'],
      ['pre', ['true']],
      ['post', ['true']],
      [
        ['rule', [['pcons', 'True', []]], ['cons', 'False', []]],
        ['rule', [['pcons', 'False', []]], ['cons', 'True', []]]
      ]
    ]

    expected_sig = 'Term* f_0(Term* x_0);'
    expected_fun = <<~HEREDOC
      Term* f_0(Term* x_0) {
          if (x_0->tag == 4) {
              Term* e_0 = new Term();
              e_0->tag = 5;
              e_0->refcnt = 0;
              Term* res = e_0;
              incref(res);
              return res;
          }

          if (x_0->tag == 5) {
              Term* e_1 = new Term();
              e_1->tag = 4;
              e_1->refcnt = 0;
              Term* res = e_1;
              incref(res);
              return res;
          }

          Term* e_2 = new Term();
          e_2->tag = 5;
          e_2->refcnt = 0;
          Term* res = e_2;
          incref(res);
          return res;
      }
    HEREDOC

    compiledf = subject.compile(function, context)

    expect(compiledf[:signature]).to eq(expected_sig)
    expect(compiledf[:code]).to eq(expected_fun)
  end

  def context
    tags = { 'Cons' => 0, 'Zero' => 1, 'Suc' => 2, 'Nil' => 3, 'True' => 4, 'False' => 5 }
    Pipeline::Compiler.new.build_fresh_context(tags)
  end
end
