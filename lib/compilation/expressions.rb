# frozen_string_literal: true

module Compilation
  class Expressions
    def compile(expression, context, spaces_qty: 1)
      current_context = context

      children = expression[2].map do |e|
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

      case type
      when 'cons'
        var = context[:next_var_id]
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
        Compilation::Functions.new.compile_app(expression, context)[:code]
      end
    end
  end
end
