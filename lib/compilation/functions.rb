# frozen_string_literal: true

module Compilation
  class Functions
    def compile(function, context)
      original_name = function[1]
      function_rename = context[:functions][original_name]
      raw_sig = function[2]

      pre_name = function_rename.gsub('f', 'pre')
      precondition = build_signature('void', raw_sig, pre_name)
      compiled_pre = build_contract(function[3][1], precondition, context, original_name, 'pre')

      post_name = function_rename.gsub('f', 'post')
      postcondition = build_signature('void', raw_sig, post_name)
      compiled_pos = build_contract(function[4][1], postcondition, context, original_name, 'post')

      signature = build_signature('Term*', raw_sig, function_rename)
      compiled_f = build_function(function, function_rename, signature, context)

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
        local_context[:binded_vars] = sig[:raw_sig][1].each_with_index.each_with_object({}) do |(r, idx), m|
          m[r] = "x_#{idx}"
        end
        local_context[:binded_vars][sig[:raw_sig][2]] = 'res'

        compiled = compile_exp(raw_contract, local_context)

        f += compiled[:code]

        f += <<~HEREDOC
          #{spaces}if (!#{compiled[:tag]}) {
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

    def build_signature(return_type, raw_sig, function_name)
      params = raw_sig[1].each_with_index.map { |_, idx| "x_#{idx}" }

      params_with_type = params.map { |p| "Term* #{p}" }
      params_with_type << 'Term* res' if function_name.include?('post_')
      params_with_type = params_with_type.join(', ')

      {
        sig: "#{return_type} #{function_name}(#{params_with_type})",
        args_without_type: params.join(', '),
        raw_sig: raw_sig
      }
    end

    def build_function(function, new_name, signature, context)
      arity = function[2][1].length
      body = function.last
      current_context = context

      function = <<~HEREDOC
        #{signature[:sig]} {
            #{new_name.gsub('f', 'pre')}(#{signature[:args_without_type]});
      HEREDOC

      function = body.reduce(function) do |f, c|
        compiled_case = build_case(c, arity, context, signature, new_name)
        current_context = context
        f + compiled_case[:code]
      end

      if arity.zero?
        function += <<~HEREDOC
              #{new_name.gsub('f', 'post')}(e_#{current_context[:next_var_id] - 1});
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

    def build_case(kase, arity, context, signature, new_name)
      return compile_exp(kase[2], context) if arity.zero?

      context[:binded_vars] = {}
      context[:conditions] = {}
      binded = ebuilder.deconstruct(kase[1], context, signature[:args_without_type].split(', '))

      code = binded[:code]
      binded_context = binded[:context]

      conditions = compile_conditions(binded_context[:conditions])

      spaces_qty = conditions.empty? ? 1 : 2
      compiled = compile_exp(kase[2], binded_context, spaces_qty: spaces_qty)

      unless conditions.empty?
        code += <<~HEREDOC
          #{spaces}if (#{conditions.join(' && ')}) {
        HEREDOC
      end

      code += compiled[:code]

      code += <<~HEREDOC
        #{spaces * spaces_qty}Term* res = #{compiled[:tag]};
        #{spaces * spaces_qty}incref(res);
        #{spaces * spaces_qty}#{new_name.gsub('f', 'post')}(#{signature[:args_without_type]}, res);
        #{spaces * spaces_qty}return res;
        #{spaces}#{conditions.empty? ? '' : '}'}\n
      HEREDOC

      compiled.tap { |c| c[:code] = code }
    end

    def compile_conditions(conditions)
      conditions.map { |var, tag| "#{var}->tag == #{tag}" }
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
