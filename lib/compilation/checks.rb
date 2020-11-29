# frozen_string_literal: true

module Compilation
  class Checks
    def compile_print(print_arg)
      <<~HEREDOC
        #{spaces}incref(#{print_arg});
        #{spaces}printTerm(#{print_arg}, tags);
        #{spaces}cout << "\\n";
        #{spaces}decref(#{print_arg});\n
      HEREDOC
    end

    private

    def spaces
      "\x20\x20\x20\x20"
    end
  end
end
