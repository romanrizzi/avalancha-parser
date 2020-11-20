# frozen_string_literal: true

require 'tempfile'
require_relative '../compilation/program'

module Pipeline
  class Compiler
    def compile(tags, ast)
      @check_vars = 0

      Compilation::Program.new(tags).tap do |program|
        checks = ast[2]
        checks.each { |c| add_check_to(program, c) }

        program.build_main_method
      end
    end

    def compile_and_run(tags, ast)
      file = Tempfile.new(%w[source .cpp])
      output = Tempfile.new('compiled')
      begin
        program = compile(tags, ast)

        file.write(program.to_s)
        file.rewind

        `g++ -o #{output.path} #{file.path} && #{output.path}`
      ensure
        file.close
        file.unlink   # deletes the temp file
        output.close
        output.unlink
      end
    end

    private

    def add_check_to(program, check)
      case check.first
      when 'print'
        var_number = compile_expression(program, check[1])
        program.add_print(var_number)
      end
    end

    def compile_expression(program, expression)
      children_vars = if expression[2].empty?
                        []
                      else
                        expression[2].map { |e| compile_expression(program, e) }
                      end

      var = @check_vars

      program.add_expression(
        tag: expression[1],
        var: var,
        children: children_vars
      )

      @check_vars += 1
      var
    end
  end
end
