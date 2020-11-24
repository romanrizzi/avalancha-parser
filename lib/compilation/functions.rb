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
              e_#{var}->tag = #{current_context.dig(:tags, 'False')};
              e_#{var}->refcnt = 0;
              Term* failed_check = e_#{var};
              incref(failed_check);
              return failed_check;
          }
        HEREDOC
      end

      { code: function, context: current_context }
    end

    def build_case(kase, arity, context)
      return compile_exp(kase[2], context) if arity.zero?

      new_context = add_pvars(context, kase[1])
      conditions = compile_conditions(kase[1], new_context)

      spaces_qty = conditions.empty? ? 1 : 2
      compiled = compile_exp(kase[2], new_context, spaces_qty: spaces_qty)

      code = ''

      unless conditions.empty?
        code += <<~HEREDOC
          #{spaces}if (#{conditions.join}) {
        HEREDOC
      end

      code += compiled[:code]

      code += <<~HEREDOC
        #{spaces * spaces_qty}Term* res = e_#{compiled.dig(:context, :next_var_id) - 1};
        #{spaces * spaces_qty}incref(res);
        #{spaces * spaces_qty}return res;
        #{spaces}#{conditions.empty? ? '' : '}'}\n
      HEREDOC

      compiled.tap { |c| c[:code] = code }
    end

    def compile_conditions(raw_conds, context)
      pconss = raw_conds.reject { |p| %w[pvar pwild].include?(p[0]) }

      pconss.each_with_index.map do |pcons, idx|
        cond = "x_#{idx}->tag == #{context.dig(:tags, pcons[1])}"
        cond += ' && ' if idx < pconss.length - 1
        cond
      end
    end

    def add_pvars(context, args)
      case_args = {}
      arg_n = 0

      args.each do |a|
        case_args[a[1]] = "x_#{arg_n}" if a[0] == 'pvar'
        arg_n += 1
      end

      context[:f_args] = case_args
      context
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
