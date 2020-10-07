# frozen_string_literal: true

require 'spec_helper'
require 'json'
require_relative '../../lib/avalancha'

describe Avalancha do
  let(:instance) { Avalancha.build }

  %w[
    test00 test01 test02 test03
    test04 test05 test06 test07
    test08 test09 test10 test11
    test12
  ].each do |test_name|
    it "passes #{test_name}" do
      assert_works_with_test_file(test_name)
    end
  end

  def assert_works_with_test_file(test_name)
    expected = JSON.parse(File.read(build_path(test_name, 'expected')))

    result = instance.parse(build_path(test_name, 'input'))

    expect(result).to eq(expected)
  end

  def build_path(test_name, ext)
    "examples/#{test_name}.#{ext}"
  end
end
