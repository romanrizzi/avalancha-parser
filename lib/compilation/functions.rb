# frozen_string_literal: true

module Compilation
  class Functions
    def compile(function, context)
      function_rename = "f_#{context[:next_fun_id]}"
      original_name = function[1]
      context[:functions][original_name] = function_rename
      raw_sig = function[2]

      pre_name = "pre_#{context[:next_fun_id]}"
      precondition = build_signature('void', raw_sig[1].length, pre_name)
      compiled_pre = build_contract(function[3][1], precondition, context, original_name, 'pre')

      post_name = "post_#{context[:next_fun_id]}"
      postcondition = build_signature('void', raw_sig[1].length, post_name)
      compiled_pos = build_contract(function[4][1], postcondition, context, original_name, 'post')

      signature = build_signature('Term*', raw_sig[1].length, function_rename)
      compiled_f = build_function(function, signature, context)

      compiled_f[:context][:next_fun_id] += 1

      {
        signatures: [signature, precondition, postcondition].map! { |s| s[:sig] += ';' },
        code: [compiled_pre, compiled_pos, compiled_f[:code]].join("\n"),
        context: compiled_f[:context]
      }
    end

    private

    def build_contract(raw_contract, sig, context, original_name, type)
      local_context = context.dup.merge(next_var_id: 0)

      f = <<~HEREDOC
        #{sig[:sig]} {
      HEREDOC

      if raw_contract[0] != 'true'
        l_side = compile_exp(raw_contract[1], local_context)
        r_side = compile_exp(raw_contract[2], l_side[:context])

        f += l_side[:code]
        f += r_side[:code]

        f += <<~HEREDOC
          #{spaces}if (!eqTerms(#{l_side[:tag]}, #{r_side[:tag]})) {
          #{spaces * 2}cout << "#{type}(#{original_name}) failed";
          #{spaces * 2}exit(1);
          #{spaces}}
        HEREDOC
      end

      <<~HEREDOC
        #{f}
        }
      HEREDOC
    end

    def build_signature(return_type, args_qty, function_name)
      params = []
      args_qty.times { |idx| params << "x_#{idx}" }

      params_with_type = params.map { |p| "Term* #{p}" }
      params_with_type << 'Term* res' if function_name.include?('post_')
      params_with_type = params_with_type.join(', ')

      {
        sig: "#{return_type} #{function_name}(#{params_with_type})",
        args_without_type: params.join(', ')
      }
    end

    def build_function(function, signature, context)
      arity = function[2][1].length
      body = function.last
      current_context = context

      function = <<~HEREDOC
        #{signature[:sig]} {
            pre_#{context[:next_fun_id]}(#{signature[:args_without_type]});
      HEREDOC

      function = body.reduce(function) do |f, c|
        compiled_case = build_case(c, arity, context, signature)
        current_context = context
        f + compiled_case[:code]
      end

      if arity.zero?
        function += <<~HEREDOC
              post_#{context[:next_fun_id]}(e_#{current_context[:next_var_id] - 1});
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

    def build_case(kase, arity, context, signature)
      return compile_exp(kase[2], context) if arity.zero?

      context[:f_vars] = {}
      new_context = add_pvars(context, kase[1])
      conditions = compile_conditions(kase[1], new_context)

      spaces_qty = conditions.empty? ? 1 : 2
      compiled = compile_exp(kase[2], new_context, spaces_qty: spaces_qty)

      code = ''

      unless conditions.empty?
        code += <<~HEREDOC
          #{spaces}if (#{conditions.join(' && ')}) {
        HEREDOC
      end

      code += compiled[:code]

      code += <<~HEREDOC
        #{spaces * spaces_qty}Term* res = #{compiled[:tag]};
        #{spaces * spaces_qty}incref(res);
        #{spaces * spaces_qty}post_#{context[:next_fun_id]}(#{signature[:args_without_type]}, res);
        #{spaces * spaces_qty}return res;
        #{spaces}#{conditions.empty? ? '' : '}'}\n
      HEREDOC

      compiled.tap { |c| c[:code] = code }
    end

    def compile_conditions(raw_conds, context)
      raw_conds.each_with_index.each_with_object([]) do |(p, idx), m|
        next if %w[pvar pwild].include?(p[0])

        kond = "x_#{idx}->tag == #{context.dig(:tags, p[1])}"
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
