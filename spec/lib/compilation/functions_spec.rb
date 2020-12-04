# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/compilation/functions'
require_relative '../../../lib/pipeline/compiler'

describe Compilation::Functions do
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
      void pre_0(Term* x_0) {

      }

      void post_0(Term* x_0, Term* res) {

      }

      Term* f_0(Term* x_0) {
          pre_0(x_0);
          Term* e_0 = x_0;
          if (e_0->tag == 4) {
              Term* e_1 = new Term();
              e_1->tag = 5;
              e_1->refcnt = 0;
              Term* res = e_1;
              incref(res);
              post_0(x_0, res);
              return res;
          }

          Term* e_2 = x_0;
          if (e_2->tag == 5) {
              Term* e_3 = new Term();
              e_3->tag = 4;
              e_3->refcnt = 0;
              Term* res = e_3;
              incref(res);
              post_0(x_0, res);
              return res;
          }

          Term* e_4 = new Term();
          e_4->tag = 5;
          e_4->refcnt = 0;
          Term* failed_check = e_4;
          incref(failed_check);
          return failed_check;
      }
    HEREDOC

    compiledf = subject.compile(function, context('neg'))

    expect(compiledf[:signatures].first).to eq(expected_sig)
    expect(compiledf[:code]).to eq(expected_fun)
  end

  it 'compiles a function with arguments' do
    fun = [
      'fun',
      'sucsuc',
      ['sig', ['_'], '_'],
      ['pre', ['true']],
      ['post', ['true']],
      [
        ['rule',
         [%w[pvar x]],
         ['cons', 'Suc', [['cons', 'Suc', [%w[var x]]]]]]
      ]
    ]

    expected_fun = <<~HEREDOC
      void pre_0(Term* x_0) {

      }

      void post_0(Term* x_0, Term* res) {

      }

      Term* f_0(Term* x_0) {
          pre_0(x_0);
          Term* e_0 = x_0;
          incref(e_0);
          Term* e_1 = new Term();
          e_1->tag = 2;
          e_1->refcnt = 0;
          e_1->children.push_back(e_0);
          Term* e_2 = new Term();
          e_2->tag = 2;
          e_2->refcnt = 0;
          e_2->children.push_back(e_1);
          Term* res = e_2;
          incref(res);
          post_0(x_0, res);
          return res;
          

          Term* e_3 = new Term();
          e_3->tag = 5;
          e_3->refcnt = 0;
          Term* failed_check = e_3;
          incref(failed_check);
          return failed_check;
      }
    HEREDOC

    compiledf = subject.compile(fun, context('sucsuc'))

    expect(compiledf[:code]).to eq(expected_fun)
  end

  def context(fun_name)
    tags = { 'Cons' => 0, 'Zero' => 1, 'Suc' => 2, 'Nil' => 3, 'True' => 4, 'False' => 5 }
    Pipeline::Compiler.new.build_fresh_context(tags).tap do |c|
      c[:functions] = { fun_name => 'f_0' }
    end
  end
end
