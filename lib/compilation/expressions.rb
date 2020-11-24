# frozen_string_literal: true

module Compilation
  class Expressions
    def compile(expression, context, spaces_qty: 1)
      current_context = context

      children = (expression[2] || []).map do |e|
        compile(e, current_context).tap do |compiled|
          current_context = compiled[:context]
        end
      end

      current = current_context[:next_var_id]

      code = children.reduce('') { |m, c| m + c[:code] }

      code += generate_code(
        expression,
        children.map { |c| c[:last_var_used] },
        current_context,
        spaces_qty
      )

      current_context[:next_var_id] += 1

      { code: code, last_var_used: current, tag: "e_#{current}", context: current_context }
    end

    private

    attr_reader :tags

    def spaces
      "\x20\x20\x20\x20"
    end

    def generate_code(expression, children_ids, context, spaces_qty)
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

        children_ids.each do |idx|
          expression += <<~HEREDOC
            #{spaces * spaces_qty}e_#{var}->children.push_back(e_#{idx});
          HEREDOC
        end

        expression
      when 'app'
        fname = context.dig(:functions, expression[1])

        params_qty = children_ids.length
        args = children_ids.each_with_index.map do |v, idx|
          idx < params_qty - 1 ? "e_#{v}, " : "e_#{v}"
        end

        "#{spaces}Term* e_#{var} = #{fname}(#{args.join});\n"
      when 'var'
        arg_name = context.dig(:f_args, expression[1])

        <<~HEREDOC
          #{spaces}Term* e_#{context[:next_var_id]} = #{arg_name};
          #{spaces}incref(e_#{context[:next_var_id]});
        HEREDOC
      end
    end
  end
end
