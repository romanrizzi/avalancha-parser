# frozen_string_literal: true

module Compilation
  class Functions
    def compile(function, context)
      function_rename = "f_#{context[:next_fun_id]}"
      original_name = function[1]

      context[:functions][original_name] = function_rename
      context[:next_fun_id] += 1

      signature = build_signature(function, function_rename)
      function = build_function(function, signature, context)

      { signature: [signature, ';'].join, code: function[:code], context: function[:context] }
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

      context[:f_vars] = {}
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
      actual_args = raw_conds.reject { |rc| %w[pvar pwild].include?(rc[0]) }.length

      raw_conds.each_with_index.each_with_object([]) do |(p, idx), m|
        next if %w[pvar pwild].include?(p[0])

        kond = "x_#{idx}->tag == #{context.dig(:tags, p[1])}"
        kond += ' && ' if idx < actual_args - 1
        m << kond
      end
    end

    def add_pvars(context, args, children: false, arg_n: 0)
      current_context = context
      arg = arg_n

      args.each do |a|
        case a[0]
        when 'pvar'
          current_context[:f_vars][a[1]] = { name: "x_#{arg}", children: children }
        when 'pcons'
          current_context = add_pvars(context, a[2], children: true, arg_n: arg)
        end

        arg += 1
      end

      current_context
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
