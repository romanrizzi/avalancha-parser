# frozen_string_literal: true

module Compilation
  class Expressions
    def compile(expression, context)
      current_context = context

      children = expression[2].map do |e|
        compile(e, current_context).tap do |compiled|
          current_context = compiled[:context]
        end
      end

      current = current_context[:last_var_id_used]

      code = children.reduce('') { |m, c| m + c[:code] }

      code += generate_code(
        expression,
        children.map { |c| c[:last_var_used] },
        current_context
      )

      current_context[:last_var_id_used] += 1

      { code: code, last_var_used: current, tag: "e_#{current}", context: current_context }
    end

    private

    attr_reader :tags

    def spaces
      "\x20\x20\x20"
    end

    def generate_code(expression, children_ids, context)
      type = expression[0]

      case type
      when 'cons'
        var = context[:last_var_id_used]
        tag = context.dig(:tags, expression[1])

        expression = <<~HEREDOC
          #{spaces} Term* e_#{var} = new Term();
          #{spaces} e_#{var}->tag = #{tag};
          #{spaces} e_#{var}->refcnt = 0;
        HEREDOC

        children_ids.each do |idx|
          expression += <<~HEREDOC
            #{spaces} e_#{var}->children.push_back(e_#{idx});
          HEREDOC
        end

        expression
      when 'app'
        Compilation::Functions.new.compile_app(expression, context)[:code]
      end
    end
  end
end
