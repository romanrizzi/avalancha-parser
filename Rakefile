# frozen_string_literal: true

require_relative 'lib/avalancha'

task :lex_file, [:path] do |_, args|
  puts "-----  Lexing #{args[:path]} -----"
  puts "\n"

  tokens = Avalancha.build.lex(args[:path])

  puts tokens.map { |token| token.type }.to_s.gsub("\n", '')

  puts "\n"
end

task :parse_file, [:path] do |_, args|
  puts "-----  Parsing #{args[:path]} -----"
  puts "\n"
  
  pp Avalancha.build.parse(args[:path])
  
  puts "\n"
end
