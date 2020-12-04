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

        current = current_context[:next_var_id]

        code = children.reduce('') { |m, c| m + c[:code] }
        code += generate_code(
          expression,
          children.map { |c| c[:tag] },
          current_context,
          spaces_qty
        )

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
        "#{spaces * spaces_qty}bool e_#{var} = eqTerms(#{children_vars.join(', ')});"
      when 'and'
        "#{spaces * spaces_qty}bool e_#{var} = #{children_vars.join(' && ')};"
      when 'or'
        "#{spaces * spaces_qty}bool e_#{var} = #{children_vars.join(' || ')};"
      when 'imp'
        "#{spaces * spaces_qty}bool e_#{var} = !#{children_vars[0]} || #{children_vars[1]};"
      when 'not'
        "#{spaces * spaces_qty}bool e_#{var} = !#{children_vars[0]};"
      end
    end
  end
end
