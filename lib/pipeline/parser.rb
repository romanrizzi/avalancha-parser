# frozen_string_literal: true

require 'rltk/parser'
require 'byebug'

module Pipeline
  class Parser < RLTK::Parser
    class Environment < Environment
      def populate_signature(sig, rules)
        return sig unless sig[1].empty? && !rules.empty?

        arity = rules[0][1].size
        new_args = ['_'] * arity

        ['sig', new_args, sig[2]]
      end
    end

    production(:program) do
      clause('') { ['program', [], []] }
      clause('definitions checks') do |defs, checks|
        ['program', defs, checks]
      end
    end

    production(:definitions) do
      clause('') { [] }
      clause('definition definitions') { |d, ds| [d] + ds }
    end

    production(:definition) do
      clause('FUN LOWERID signature precondition postcondition rules') do |_, fname, s, pre, post, r|
        ['fun', fname, populate_signature(s, r), pre, post, r]
      end
    end

    production(:signature) do
      clause('') { ['sig', [], '_'] }
      clause('COLON param_list ARROW param') { |_, pl, _, param| ['sig', pl, param] }
    end

    production(:precondition) do
      clause('') { ['pre', ['true']] }
      clause('QUESTION neg_and_or_imp_formula') { |_, f| ['pre', f] }
    end

    production(:postcondition) do
      clause('') { ['post', ['true']] }
      clause('BANG neg_and_or_imp_formula') { |_, f| ['post', f] }
    end

    production(:rules) do
      clause('') { [] }
      clause('rule rules') { |r, rs| [r] + rs }
    end

    production(:rule) do
      clause('pattern_list ARROW expression') { |pl, _, e| ['rule', pl, e] }
    end

    production(:pattern_list) do
      clause('') { [] }
      clause('non_empty_pattern_list') { |nepl| nepl }
    end

    production(:non_empty_pattern_list) do
      clause('pattern') { |pat| [pat] }
      clause('pattern COMMA non_empty_pattern_list') { |pat, _, pl| [pat] + pl }
    end

    production(:pattern) do
      clause('UNDERSCORE') { |_| ['pwild'] }
      clause('LOWERID') { |id| ['pvar', id] }
      clause('UPPERID') { |id| ['pcons', id, []] }
      clause('UPPERID LPAREN pattern_list RPAREN') { |id, _, pl, _| ['pcons', id, pl] }
    end

    production(:param_list) do
      clause('') { [] }
      clause('non_empty_param_list') { |l| l }
    end

    production(:non_empty_param_list) do
      clause('param') { |param| [param] }
      clause('param COMMA non_empty_param_list') { |paraml, _, non_empty_list| [paraml] + non_empty_list }
    end

    production(:param) do
      clause('LOWERID') { |id| id }
      clause('UNDERSCORE') { |_| '_' }
    end

    production(:checks) do
      clause('') { [] }
      clause('check checks') { |c, cs| [c] + cs }
    end

    production(:check) do
      clause('PRINT expression') { |_, e| ['print', e] }
      clause('CHECK neg_and_or_imp_formula') { |_, a| ['check', a] }
    end

    production(:neg_and_or_imp_formula) do
      clause('neg_and_or_formula') { |f| f }
      clause('neg_and_or_formula IMP neg_and_or_imp_formula') { |f1, _, f2| ['imp', f1, f2] }
    end

    production(:neg_and_or_formula) do
      clause('neg_and_formula') { |f| f }
      clause('neg_and_formula OR neg_and_or_formula') { |f1, _, f2| ['or', f1, f2] }
    end

    production(:neg_and_formula) do
      clause('neg_formula') { |f| f }
      clause('neg_formula AND neg_and_formula') { |f1, _, f2| ['and', f1, f2] }
    end

    production(:neg_formula) do
      clause('atomic_formula') { |f| f }
      clause('NOT neg_formula') { |_, f| ['not', f] }
    end

    production(:atomic_formula) do
      clause('TRUE') { |_| ['true'] }
      clause('FALSE') { |_| ['false'] }
      clause('LPAREN neg_and_or_imp_formula RPAREN') { |_, f, _| f }
      clause('expression') { |e1| ['equal', e1, ['cons', 'True', []]] }
      clause('expression EQ expression') { |e1, _, e2| ['equal', e1, e2] }
    end

    production(:expression) do
      clause('LOWERID') { |id| ['var', id] }
      clause('UPPERID') { |id| ['cons', id, []] }

      clause('LOWERID LPAREN expression_list RPAREN') { |id, _, el, _| ['app', id, el] }
      clause('UPPERID LPAREN expression_list RPAREN') { |id, _, el, _| ['cons', id, el] }
    end

    production(:expression_list) do
      clause('') { [] }
      clause('non_empty_expression_list') { |el| el }
    end

    production(:non_empty_expression_list) do
      clause('expression') { |e| [e] }
      clause('expression COMMA non_empty_expression_list') { |e, _, el| [e] + el }
    end

    finalize
  end
end
