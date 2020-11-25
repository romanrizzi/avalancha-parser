# frozen_string_literal: true

require 'tempfile'
require_relative '../compilation/program'
require_relative '../compilation/expressions'
require_relative '../compilation/functions'
require_relative '../compilation/checks'

module Pipeline
  class Compiler
    def compile(tags, ast)
      @context = build_fresh_context(tags)

      @fbuilder = Compilation::Functions.new
      @ebuilder = Compilation::Expressions.new
      @cbuilder = Compilation::Checks.new

      Compilation::Program.new(@context[:tags]).tap do |program|
        defs = ast[1]
        defs.each { |d| add_def_to(program, d) }

        checks = ast[2]
        checks.each { |c| add_check_to(program, c) }
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
        file.unlink # deletes the temp file
        output.close
        output.unlink
      end
    end

    def build_fresh_context(tags)
      tags['False'] = tags.size if tags['False'].nil?

      {
        functions: {},
        next_fun_id: 0,
        next_var_id: 0,
        tags: tags
      }
    end

    private

    def add_check_to(program, check)
      case check.first
      when 'print'
        compiled = @ebuilder.compile(check[1], @context)

        @context = compiled[:context]
        compiled_print = @cbuilder.compile_print(compiled[:tag])

        program.add_check(compiled[:code])
        program.add_check(compiled_print)
      end
    end

    def add_def_to(program, definition)
      # We can reuse var ids since we are inside a function.
      local_context = @context.merge(next_var_id: 0)

      compiled = @fbuilder.compile(definition, local_context)

      @context = compiled[:context].merge(next_var_id: @context[:next_var_id])

      compiled[:signatures].each { |s| program.add_prototype(s) }
      program.add_function(compiled[:code])
    end
  end
end
