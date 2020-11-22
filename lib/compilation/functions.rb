# frozen_string_literal: true

module Compilation
  class Functions
    def compile(function, context)
      function_rename = "f_#{context[:last_fun_id_used]}"
      original_name = function[1]

      context[:functions][original_name] = function_rename
      context[:last_fun_id_used] += 1

      returned_expr = function.last.first[2]
      signature = "Term* #{function_rename}();"

      exp = compile_exp(returned_expr, context)

      function = <<~HEREDOC
        Term* #{function_rename}() {
      HEREDOC

      function += exp[:code]

      function += <<~HEREDOC

            return e_#{exp[:last_var_used]};
        }
      HEREDOC

      { signature: signature, code: function, context: context }
    end

    def compile_app(app, context)
      original_name = app[1]
      var = context[:last_var_id_used]

      {
        code: "Term* e_#{var} = #{context.dig(:functions, original_name)}();\n",
        tag: "e_#{var}",
        context: context
      }
    end

    private

    def compile_exp(exp, context)
      ebuilder.compile(exp, context)
    end

    def ebuilder
      @ebuilder ||= Compilation::Expressions.new
    end
  end
end
