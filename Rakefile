# frozen_string_literal: true

require_relative 'lib/avalancha'

task :lex_file, [:path] do |_, args|
  puts "-----  Lexing #{args[:path]} -----"
  puts "\n"

  tokens = Avalancha.build.lex(args[:path])

  puts tokens.map(&:type).to_s.gsub("\n", '')

  puts "\n"
end

task :parse_file, [:path] do |_, args|
  puts "-----  Parsing #{args[:path]} -----"
  puts "\n"

  pp Avalancha.build.parse(args[:path])

  puts "\n"
end

task :print_compiled, [:path] do |_, args|
  puts "-----  Compiling #{args[:path]} -----"
  puts "\n"

  program = Avalancha.build.compile(args[:path])
  puts program.to_s

  puts "\n"
end
