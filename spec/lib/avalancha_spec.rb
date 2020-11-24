# frozen_string_literal: true

require 'spec_helper'
require 'json'
require_relative '../../lib/avalancha'

describe Avalancha do
  let(:instance) { Avalancha.build }

  describe 'Parser' do
    let(:folder) { 'parser' }

    %w[
      test00 test01 test02 test03
      test04 test05 test06 test07
      test08 test09 test10 test11
      test12 test13 test14
    ].each do |test_name|
      it "passes #{test_name}" do
        assert_parses_test_file(folder, test_name)
      end
    end

    def assert_parses_test_file(folder, test_name)
      expected = JSON.parse(File.read(build_path(folder, test_name, 'expected')))

      result = instance.parse(build_path(folder, test_name, 'input'))

      expect(result).to eq(expected)
    end
  end

  describe 'Code generation' do
    let(:folder) { 'codegen' }

    %w[
      01 02 03 04 05
    ].each do |test_name|
      it "passes #{test_name}" do
        assert_compiles_test_file(folder, test_name)
      end
    end

    def assert_compiles_test_file(folder, test_name)
      result = instance.compile_and_run(build_path(folder, test_name, 'input')).split("\n")

      expected_path = build_path(folder, test_name, 'expected')
      expected = File.read(expected_path).split("\n")

      expect(result).to contain_exactly(*expected)
    end
  end

  def build_path(folder, test_name, ext)
    "examples/#{folder}/#{test_name}.#{ext}"
  end
end
