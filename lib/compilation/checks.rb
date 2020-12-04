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

    def compile_check(arg)
      <<~HEREDOC
        #{spaces}if (!#{arg}) {
        #{spaces * 2}cout << "check failed" << "\\n";
        #{spaces * 2}exit(1);
        #{spaces}}
      HEREDOC
    end

    private

    def spaces
      "\x20\x20\x20\x20"
    end
  end
end
