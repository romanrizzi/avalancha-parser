# frozen_string_literal: true

module Compilation
  class Expressions
    def compile(expression, context, spaces_qty: 1)
      current_context = context

      children = binary_expression?(expression[0]) ? expression[1..-1] : expression[2]

      children = (children || []).map do |e|
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
    end

    def deconstruct(patterns, context, vars)
      code = ''
      current_context = context

      patterns.each_with_index do |p, idx|
        next if p.first == 'pwild'

        compiled = compile_pattern(p, current_context, vars[idx])

        current_context = compiled[:context]
        code += compiled[:code]

        next unless p.first != 'pvar'

        compiled_subpattern = deconstruct(p[2], compiled[:context], compiled[:next_vars])
        code += compiled_subpattern[:code]
        current_context = compiled_subpattern[:context]
      end

      { code: code, context: current_context }
    end

    private

    attr_reader :tags

    def binary_expression?(name)
      %w[and equal].include?(name)
    end

    def spaces
      "\x20\x20\x20\x20"
    end

    def compile_pattern(pattern, context, val)
      return { code: '', context: context } if pattern.empty?

      case pattern.first
      when 'pcons'
        var = context[:next_var_id]
        context[:next_var_id] += 1

        code = <<~HEREDOC
          #{spaces}Term* e_#{var} = #{val};
        HEREDOC

        context[:conditions]["e_#{var}"] = context.dig(:tags, pattern[1])
        next_vars = pattern[2].each_with_index.map { |_p, idx| "e_#{var}->children[#{idx}]" }

        { code: code, context: context, next_vars: next_vars }
      when 'pvar'
        context[:binded_vars][pattern[1]] = val

        { code: '', context: context }
      end
    end

    def generate_code(expression, children_vars, context, spaces_qty)
      type = expression[0]
      var = context[:next_var_id]

      case type
      when 'cons'
        tag = context.dig(:tags, expression[1])

        expression = <<~HEREDOC
          #{spaces * spaces_qty}Term* e_#{var} = new Term();
          #{spaces * spaces_qty}e_#{var}->tag = #{tag};
          #{spaces * spaces_qty}e_#{var}->refcnt = 0;
        HEREDOC

        children_vars.each do |cv|
          expression += <<~HEREDOC
            #{spaces * spaces_qty}e_#{var}->children.push_back(#{cv});
          HEREDOC
        end

        expression
      when 'app'
        fname = context.dig(:functions, expression[1])

        "#{spaces}Term* e_#{var} = #{fname}(#{children_vars.join(', ')});\n"
      when 'var'
        binded_var = context.dig(:binded_vars, expression[1])

        <<~HEREDOC
          #{spaces}Term* e_#{var} = #{binded_var};
          #{spaces}incref(e_#{var});
        HEREDOC
      when 'equal'
        <<~HEREDOC
          #{spaces}bool e_#{var} = eqTerms(#{children_vars.join(', ')});
        HEREDOC
      when 'and'
        <<~HEREDOC
          #{spaces}bool e_#{var} = #{children_vars.join(' && ')};
        HEREDOC
      end
    end
  end
end
