# frozen_string_literal: true

module Compilation
  class Formulas
    def compile(expression, context, spaces_qty: 1)
      current_context = context

      if formula?(expression[0])
        children_exp = binary_formula?(expression[0]) ? expression[1..-1] : [expression[1]]

        children = (children_exp || []).map do |e|
          compile(e, current_context).tap do |compiled|
            current_context = compiled[:context]
          end
        end

        code = children.reduce('') { |m, c| m + c[:code] }
        code += generate_code(
          expression,
          children.map { |c| c[:tag] },
          current_context,
          spaces_qty
        )

        current = current_context[:next_var_id]
        current_context[:next_var_id] += 1

        { code: code, tag: "e_#{current}", context: current_context }
      else
        ebuilder = Compilation::Expressions.new

        compiled = ebuilder.compile(expression, current_context)
        current_context = compiled[:context]
        compiled
      end
    end

    private

    def formula?(name)
      %w[and equal or imp not].include?(name)
    end

    def binary_formula?(name)
      %w[and equal or imp].include?(name)
    end

    def spaces
      "\x20\x20\x20\x20"
    end

    def generate_code(expression, children_vars, context, spaces_qty)
      type = expression[0]
      var = context[:next_var_id]

      case type
      when 'equal'
        context[:next_var_id] += 2

        <<~HEREDOC
          #{spaces * spaces_qty}Term* e_#{var} = #{children_vars[0]};
          #{spaces * spaces_qty}incref(e_#{var});
          #{spaces * spaces_qty}Term* e_#{var + 1} = #{children_vars[1]};
          #{spaces * spaces_qty}incref(e_#{var + 1});
          #{spaces * spaces_qty}bool e_#{var + 2} = eqTerms(e_#{var}, e_#{var + 1});
          #{spaces * spaces_qty}decref(e_#{var});
          #{spaces * spaces_qty}decref(e_#{var + 1});
        HEREDOC
      when 'and'
        <<~HEREDOC
          #{spaces * spaces_qty}bool e_#{var} = #{children_vars[0]};
          #{spaces * spaces_qty}if (e_#{var}) {
          #{spaces * (spaces_qty + 1)}bool e_#{var} = #{children_vars[1]};
          #{spaces * spaces_qty}}
        HEREDOC
      when 'or'
        <<~HEREDOC
          #{spaces * spaces_qty}bool e_#{var} = #{children_vars[0]};
          #{spaces * spaces_qty}if (!e_#{var}) {
          #{spaces * (spaces_qty + 1)}bool e_#{var} = #{children_vars[1]};
          #{spaces * spaces_qty}}
        HEREDOC
      when 'imp'
        <<~HEREDOC
          #{spaces * spaces_qty}bool e_#{var} = !#{children_vars[0]};
          #{spaces * spaces_qty}if (!e_#{var}) {
          #{spaces * (spaces_qty + 1)}bool e_#{var} = #{children_vars[1]};
          #{spaces * spaces_qty}}
        HEREDOC
      when 'not'
        "#{spaces * spaces_qty}bool e_#{var} = !#{children_vars[0]};"
      end
    end
  end
end
