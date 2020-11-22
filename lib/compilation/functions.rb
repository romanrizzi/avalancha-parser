# frozen_string_literal: true

module Compilation
  class Functions
    def compile(function, context)
      function_rename = "f_#{context[:next_fun_id]}"
      original_name = function[1]

      signature = build_signature(function, function_rename)
      function = build_function(function, signature, context)

      new_context = function[:context]

      new_context[:functions][original_name] = function_rename
      new_context[:next_fun_id] += 1

      { signature: [signature, ';'].join, code: function[:code], context: new_context }
    end

    def compile_app(app, context)
      original_name = app[1]

      compiled_args = app[2].each_with_object({ code: '', vars: [], context: context }) do |a, m|
        compiled = compile_exp(a, m[:context])

        m[:code] += compiled[:code]
        m[:context] = compiled[:context]
        m[:vars] << compiled[:last_var_used]
      end

      compiled_args.tap do |ca|
        var = ca.dig(:context, :next_var_id)
        fname = ca.dig(:context, :functions, original_name)

        params_qty = ca[:vars].length
        args = ca[:vars].each_with_index.map do |v, idx|
          idx < params_qty - 1 ? "e_#{v}, " : "e_#{v}"
        end

        ca[:code] += "Term* e_#{var} = #{fname}(#{args.join});\n"
        ca[:tag] = "e_#{var}"

        ca[:context][:next_var_id] += 1
      end
    end

    private

    def build_signature(function, function_rename)
      raw_sig = function[2]
      params_qty = raw_sig[1].length

      params = raw_sig[1].each_with_index.map do |_, idx|
        idx < params_qty - 1 ? "Term* x_#{idx}, " : "Term* x_#{idx}"
      end

      "Term* #{function_rename}(#{params.join})"
    end

    def build_function(function, signature, context)
      arity = function[2][1].length
      body = function.last
      current_context = context

      function = <<~HEREDOC
        #{signature} {
      HEREDOC

      function = body.reduce(function) do |f, c|
        compiled_case = build_case(c, arity, context)
        current_context = context
        f + compiled_case[:code]
      end

      if arity.zero?
        function += <<~HEREDOC

              return e_#{current_context[:next_var_id] - 1};
          }
        HEREDOC
      else
        var = current_context[:next_var_id]
        current_context[:next_var_id] += 1

        function += <<~HEREDOC
              Term* e_#{var} = new Term();
              e_#{var}->tag = 5;
              e_#{var}->refcnt = 0;
              Term* res = e_#{var};
              incref(res);
              return res;
          }
        HEREDOC
      end

      { code: function, context: current_context }
    end

    def build_case(kase, arity, context)
      if arity.zero?
        compile_exp(kase[2], context)
      else
        pcons = kase[1][0]
        compiled = compile_exp(kase[2], context, spaces_qty: 2)

        code = <<~HEREDOC
          #{spaces}if (x_0->tag == #{context.dig(:tags, pcons[1])}) {
        HEREDOC

        code += compiled[:code]

        code += <<~HEREDOC
          #{spaces * 2}Term* res = e_#{compiled.dig(:context, :next_var_id) - 1};
          #{spaces * 2}incref(res);
          #{spaces * 2}return res;
          #{spaces}}\n
        HEREDOC

        compiled.tap { |c| c[:code] = code }
      end
    end

    def compile_exp(exp, context, spaces_qty: 1)
      ebuilder.compile(exp, context, spaces_qty: spaces_qty)
    end

    def ebuilder
      @ebuilder ||= Compilation::Expressions.new
    end

    def spaces
      "\x20\x20\x20\x20"
    end
  end
end
